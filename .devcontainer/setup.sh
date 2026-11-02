#!/usr/bin/env bash
# =============================================================================
# IST 270 — Codespace environment setup
#
# Runs once when the Codespace is first created (devcontainer postCreateCommand).
# Every step is idempotent, so this script is safe to re-run at any time:
#
#     bash .devcontainer/setup.sh
#
# What it produces:
#   1. PostgreSQL 16 installed and running on localhost:5432
#   2. superuser "postgres" with password "postgres"
#   3. database week10a (Tutoring Center workshop data)
#   4. database week10b (Event Management workshop data)
#   5. pgAdmin 4 installed in web mode on port 5050, with a pre-registered
#      server pointing at the local PostgreSQL instance
#
# Instructor note: edit the constants below to change ports, credentials, or
# which databases get created. Students never need to open this file.
# =============================================================================

set -euo pipefail

# --- Configuration ------------------------------------------------------------
PG_SUPERUSER="postgres"
PG_SUPERUSER_PASSWORD="postgres"
PG_PORT="5432"
PGADMIN_EMAIL="student@ist270.edu"
PGADMIN_PASSWORD="ist270db"
PGADMIN_PORT="5050"
WORKSHOP_A_DB="week10a"
WORKSHOP_B_DB="week10b"
PGADMIN_VENV="/opt/pgadmin"
PGADMIN_DATA_DIR="/var/lib/pgadmin"
PGADMIN_CONFIG_FILE="${PGADMIN_DATA_DIR}/config_custom.py"
# The devcontainer's non-root account. Everything pgAdmin writes must belong
# to this account, because the student runs pgadmin4-cli themselves when they
# create their own account. Chaining to "$(id -u)" instead would break that
# whenever setup.sh happens to run as root (for example "sudo bash
# .devcontainer/setup.sh"), because the files would then be root-owned and
# the student's own pgadmin4-cli calls would fail.
PGADMIN_OWNER_USER="vscode"
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSHOP_DIR="${REPO_ROOT}/workshops"

log()  { printf '\033[1;36m[IST 270 setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[IST 270 setup]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[IST 270 setup] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive

# --- Helpers ------------------------------------------------------------------
# The devcontainer image grants the student account passwordless sudo only when
# running AS ROOT ("vscode ALL=(root) NOPASSWD:ALL"). Running "sudo -u postgres"
# would therefore prompt for a password and fail during a non-interactive build,
# so every PostgreSQL superuser operation goes through root and then su.
as_postgres() {
	sudo su postgres -s /bin/bash -c "$1"
}

# Query the server over TCP using the superuser password.
psql_as_superuser() {
	local db="$1"
	shift
	PGPASSWORD="${PG_SUPERUSER_PASSWORD}" psql \
		-h localhost -p "${PG_PORT}" -U "${PG_SUPERUSER}" -d "${db}" -tAc "$*"
}

# Give a path to the student account. Falls back to the current user if the
# devcontainer account is named something else.
pgadmin_owner() {
	if id -u "${PGADMIN_OWNER_USER}" >/dev/null 2>&1; then
		printf '%s:%s' "${PGADMIN_OWNER_USER}" "${PGADMIN_OWNER_USER}"
	else
		printf '%s:%s' "$(id -u)" "$(id -g)"
	fi
}

# --- 1. PostgreSQL ------------------------------------------------------------
if ! command -v psql >/dev/null 2>&1; then
	log "Installing PostgreSQL (this takes a minute)..."
	sudo apt-get update -qq
	sudo apt-get install -y --no-install-recommends \
		postgresql postgresql-contrib python3-venv
else
	log "PostgreSQL already installed."
fi

PG_VERSION="$(ls /etc/postgresql 2>/dev/null | sort -V | tail -1)"
[ -n "${PG_VERSION}" ] || fail "Could not determine the installed PostgreSQL version."
log "PostgreSQL ${PG_VERSION} detected."

# Start the cluster. Containers have no systemd, so use pg_ctlcluster and fall
# back to the SysV wrapper. Both are harmless if the cluster is already running.
if ! pg_isready -q -h localhost -p "${PG_PORT}" 2>/dev/null; then
	sudo pg_ctlcluster "${PG_VERSION}" main start 2>/dev/null \
		|| sudo service postgresql start >/dev/null 2>&1 \
		|| true
fi

for _ in $(seq 1 30); do
	pg_isready -q -h localhost -p "${PG_PORT}" 2>/dev/null && break
	sleep 1
done
pg_isready -q -h localhost -p "${PG_PORT}" \
	|| fail "PostgreSQL did not come up on port ${PG_PORT}."
log "PostgreSQL is accepting connections on port ${PG_PORT}."

# Set the superuser password so password authentication works for every client.
# This must happen before any TCP connection is possible, so it runs as the
# PostgreSQL OS user over the local socket.
as_postgres "psql -v ON_ERROR_STOP=1 -q -c \"ALTER USER ${PG_SUPERUSER} WITH PASSWORD '${PG_SUPERUSER_PASSWORD}';\"" \
	>/dev/null

# --- 2. Databases -------------------------------------------------------------
# Both workshop databases are created up front and populated below.
for db in "${WORKSHOP_A_DB}" "${WORKSHOP_B_DB}"; do
	if [ "$(psql_as_superuser postgres "SELECT 1 FROM pg_database WHERE datname='${db}'")" = "1" ]; then
		log "Database ${db} already exists."
	else
		log "Creating database ${db}..."
		as_postgres "createdb ${db}"
	fi
done

# --- 3. Workshop datasets -----------------------------------------------------
# Load each starter only once. Re-running setup never overwrites student work.
load_workshop() {
	local db="$1" table="$2" file="$3"
	local table_count
	table_count="$(psql_as_superuser "${db}" \
		"SELECT count(*) FROM pg_tables WHERE schemaname='public' AND tablename='${table}'" \
		2>/dev/null || echo 0)"
	if [ "${table_count}" = "0" ]; then
		log "Loading the starter data into ${db}..."
		as_postgres "psql -v ON_ERROR_STOP=1 -q -d ${db}" < "${file}" >/dev/null
	else
		log "Starter data already present in ${db}; leaving it untouched."
	fi
}

load_workshop "${WORKSHOP_A_DB}" "tutors" "${WORKSHOP_DIR}/week10a/starter/week10a_database.sql"
load_workshop "${WORKSHOP_B_DB}" "venues" "${WORKSHOP_DIR}/week10b/starter/week10b_database.sql"

# --- 4. pgAdmin 4 -------------------------------------------------------------
# VERSION PIN - do not remove without checking the web assets first.
#
# pgAdmin 9.19's PyPI wheel ships only the JavaScript SOURCES
# (static/js/*.jsx) and not the BUILT bundles the browser actually loads
# (static/js/generated/vendor.*.js). The server starts and serves the HTML
# shell, but every asset 404s, the single-page app never boots, and the student
# gets a blank page with 404s for style.css and vendor.*.js in the console.
# 9.18 is the last release whose wheel includes the built assets.
#
# The verification step below is the real safety net: if a future version is
# broken the same way, the build says so loudly instead of failing silently.
PGADMIN_VERSION="9.18"
PGADMIN_BUNDLE_GLOB="${PGADMIN_VENV}/lib/python*/site-packages/pgadmin4/pgadmin/static/js/generated/vendor.react.js"

pgadmin_install() {
	sudo apt-get update -qq
	sudo apt-get install -y --no-install-recommends python3-venv
	sudo python3 -m venv "${PGADMIN_VENV}"
	sudo "${PGADMIN_VENV}/bin/pip" install --quiet --upgrade pip wheel
	sudo "${PGADMIN_VENV}/bin/pip" install --quiet "pgadmin4==${PGADMIN_VERSION}"
}

pgadmin_assets_present() {
	# shellcheck disable=SC2086
	ls ${PGADMIN_BUNDLE_GLOB} >/dev/null 2>&1
}

pgadmin_installed_version() {
	"${PGADMIN_VENV}/bin/pip" show pgadmin4 2>/dev/null \
		| awk '/^Version:/ {print $2}'
}

if [ ! -x "${PGADMIN_VENV}/bin/pgadmin4" ]; then
	log "Installing pgAdmin 4 ${PGADMIN_VERSION} (this takes a couple of minutes)..."
	pgadmin_install
elif [ "$(pgadmin_installed_version)" != "${PGADMIN_VERSION}" ]; then
	log "pgAdmin $(pgadmin_installed_version) is installed; switching to ${PGADMIN_VERSION}..."
	pgadmin_install
else
	log "pgAdmin ${PGADMIN_VERSION} already installed."
fi

# The browser assets are the thing that actually matters. Check them, and
# repair the install if they are missing.
if ! pgadmin_assets_present; then
	log "pgAdmin's built web assets are missing - reinstalling ${PGADMIN_VERSION}..."
	sudo "${PGADMIN_VENV}/bin/pip" install --quiet --force-reinstall --no-cache-dir \
		"pgadmin4==${PGADMIN_VERSION}" || true
fi
if ! pgadmin_assets_present; then
	fail "pgAdmin's built web assets are still missing after reinstalling.
     The pgAdmin browser UI will render a blank page.
     This means pgadmin4 ${PGADMIN_VERSION} does not ship them either -
     check for a newer fixed release, then update PGADMIN_VERSION at the top
     of .devcontainer/setup.sh."
fi
log "pgAdmin web assets verified (version $(pgadmin_installed_version))."

# pgAdmin in server mode stores its SQLite config database and its log under
# DATA_DIR. It must be writable by the student account.
sudo mkdir -p "${PGADMIN_DATA_DIR}"
sudo chown -R "$(pgadmin_owner)" "${PGADMIN_DATA_DIR}" 2>/dev/null || true

# pgAdmin binds to 127.0.0.1 by default, which would be unreachable from the
# Codespaces port forwarder. This config file overrides the listen address and
# keeps every pgAdmin file inside DATA_DIR.
#
# UPGRADE_CHECK_ENABLED = False stops pgAdmin from polling pgadmin.org for a
# newer release. Without it, every student sees a banner saying "You are
# currently running version 9.18 ... however the current version is 9.19",
# which reads as "this environment is broken" and invites students to try to
# upgrade a program they cannot and should not upgrade inside a Codespace.
# The pin above already decided which version is correct; the check only
# produces noise.
cat > "${PGADMIN_CONFIG_FILE}" <<'PYCONFIG'
HELP_PATH = '../../docs/en_US/_build/html/'
MINIFY_HTML = False
DATA_DIR = '/var/lib/pgadmin'
DEFAULT_SERVER = '0.0.0.0'
DEFAULT_SERVER_PORT = 5050
UPGRADE_CHECK_ENABLED = False
PYCONFIG
chown "$(pgadmin_owner)" "${PGADMIN_CONFIG_FILE}" 2>/dev/null || true

export CONFIG_DISTRO_FILE_PATH="${PGADMIN_CONFIG_FILE}"
export PGADMIN_CONFIG_DEFAULT_SERVER="0.0.0.0"

# pgAdmin creates its first administrator account while it initialises the
# configuration database. Without these two variables it stops and prompts for
# the account on the terminal, which would fail a non-interactive build.
export PGADMIN_SETUP_EMAIL="${PGADMIN_EMAIL}"
export PGADMIN_SETUP_PASSWORD="${PGADMIN_PASSWORD}"

# Create the pgAdmin configuration database and the web login account. The
# account is created by the database migration itself, so add-user afterwards
# is only a fallback. The guard checks that the configuration database is
# actually usable, and removes a half-written one left by a failed attempt.
if ! "${PGADMIN_VENV}/bin/pgadmin4-cli" get-users >/dev/null 2>&1; then
	log "Creating the pgAdmin configuration database and login account..."
	rm -f "${PGADMIN_DATA_DIR}/pgadmin4.db"
	"${PGADMIN_VENV}/bin/pgadmin4-cli" setup-db >/dev/null 2>&1 \
		|| warn "pgAdmin setup-db reported a problem; continuing."
fi

if ! "${PGADMIN_VENV}/bin/pgadmin4-cli" get-users 2>&1 | grep -q "${PGADMIN_EMAIL}"; then
	log "Creating the pgAdmin login account (${PGADMIN_EMAIL})..."
	"${PGADMIN_VENV}/bin/pgadmin4-cli" add-user \
		"${PGADMIN_EMAIL}" "${PGADMIN_PASSWORD}" --admin >/dev/null 2>&1 \
		|| warn "Could not create the pgAdmin login account automatically."
else
	log "pgAdmin login account already exists."
fi

# Pre-register the local server so students do not have to type connection
# details. This step is best-effort on purpose: if it fails the Codespace
# still works, and the README explains how to add the server by hand.
if [ -f "${SCRIPT_DIR}/pgadmin-servers.json" ] \
   && "${PGADMIN_VENV}/bin/pgadmin4-cli" get-users >/dev/null 2>&1; then
	log "Registering the local PostgreSQL server in pgAdmin..."
	"${PGADMIN_VENV}/bin/pgadmin4-cli" load-servers \
		"${SCRIPT_DIR}/pgadmin-servers.json" --user "${PGADMIN_EMAIL}" >/dev/null 2>&1 \
		|| warn "Could not pre-register the pgAdmin server — add it manually using the README."
fi

# --- 5. Start the services ----------------------------------------------------
bash "${SCRIPT_DIR}/start-services.sh"

# --- Done ---------------------------------------------------------------------
log "Setup complete."
cat <<'EOF'

  ---------------------------------------------------------------
   IST 270 database environment is ready.

   PostgreSQL : localhost:5432   user: postgres   password: postgres

   Databases  : week10a  (Tutoring Center workshop)
                week10b  (Event Management JOIN workshop)

   pgAdmin 4  : open the "pgAdmin 4" tab in the Ports panel, or
                run  bash .devcontainer/start-services.sh

   psql       : open a terminal in the Codespace and type  psql
  ---------------------------------------------------------------

EOF
