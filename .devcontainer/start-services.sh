#!/usr/bin/env bash
# =============================================================================
# IST 270 — start the database services
#
# Runs every time the Codespace container starts (devcontainer postStartCommand).
# The container may have been stopped and restarted since the last session, so
# this makes sure PostgreSQL and pgAdmin are actually running.
#
# It is safe to run this at any time:
#
#     bash .devcontainer/start-services.sh
# =============================================================================

set -uo pipefail

PG_PORT="5432"
PGADMIN_PORT="5050"
PGADMIN_EMAIL="student@ist270.edu"
PGADMIN_PASSWORD="ist270db"
PGADMIN_VENV="/opt/pgadmin"
PGADMIN_DATA_DIR="/var/lib/pgadmin"
PGADMIN_CONFIG_FILE="${PGADMIN_DATA_DIR}/config_custom.py"
# The devcontainer's non-root account. See the matching note in setup.sh:
# pgAdmin's files must belong to the student, because the student runs
# pgadmin4-cli themselves when they create their own account.
PGADMIN_OWNER_USER="vscode"

log()  { printf '\033[1;36m[IST 270]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[IST 270]\033[0m %s\n' "$*"; }

# Give a path to the student account. Falls back to the current user if the
# devcontainer account is named something else.
pgadmin_owner() {
	if id -u "${PGADMIN_OWNER_USER}" >/dev/null 2>&1; then
		printf '%s:%s' "${PGADMIN_OWNER_USER}" "${PGADMIN_OWNER_USER}"
	else
		printf '%s:%s' "$(id -u)" "$(id -g)"
	fi
}

# --- PostgreSQL ---------------------------------------------------------------
if pg_isready -q -h localhost -p "${PG_PORT}" 2>/dev/null; then
	log "PostgreSQL is already running on port ${PG_PORT}."
else
	PG_VERSION="$(ls /etc/postgresql 2>/dev/null | sort -V | tail -1)"
	if [ -n "${PG_VERSION}" ]; then
		sudo pg_ctlcluster "${PG_VERSION}" main start 2>/dev/null \
			|| sudo service postgresql start >/dev/null 2>&1 \
			|| warn "Could not start PostgreSQL. Try: sudo pg_ctlcluster ${PG_VERSION} main start"
	else
		warn "PostgreSQL is not installed. Run: bash .devcontainer/setup.sh"
	fi

	for _ in $(seq 1 30); do
		pg_isready -q -h localhost -p "${PG_PORT}" 2>/dev/null && break
		sleep 1
	done
	pg_isready -q -h localhost -p "${PG_PORT}" \
		&& log "PostgreSQL started on port ${PG_PORT}."
fi

# --- pgAdmin 4 ----------------------------------------------------------------
if [ ! -x "${PGADMIN_VENV}/bin/pgadmin4" ]; then
	warn "pgAdmin 4 is not installed. Run: bash .devcontainer/setup.sh"
	exit 0
fi

if curl -sf -o /dev/null "http://127.0.0.1:${PGADMIN_PORT}/login" 2>/dev/null; then
	log "pgAdmin 4 is already running on port ${PGADMIN_PORT}."
	exit 0
fi

# Bind to 0.0.0.0 so the Codespaces port forwarder can reach it.
export CONFIG_DISTRO_FILE_PATH="${PGADMIN_CONFIG_FILE}"
export PGADMIN_CONFIG_DEFAULT_SERVER="0.0.0.0"

# If the configuration database does not exist yet, pgAdmin would stop and
# prompt for the administrator account on the terminal. These variables make
# that first-run setup non-interactive.
export PGADMIN_SETUP_EMAIL="${PGADMIN_EMAIL}"
export PGADMIN_SETUP_PASSWORD="${PGADMIN_PASSWORD}"

mkdir -p "${PGADMIN_DATA_DIR}" 2>/dev/null || true

# pgAdmin aborts immediately if CONFIG_DISTRO_FILE_PATH points at a file that
# does not exist, so make sure the config is there before starting the server.
# The file must match the one written by setup.sh.
if [ ! -f "${PGADMIN_CONFIG_FILE}" ]; then
	log "Writing the pgAdmin configuration file..."
	cat > "${PGADMIN_CONFIG_FILE}" <<'PYCONFIG'
HELP_PATH = '../../docs/en_US/_build/html/'
MINIFY_HTML = False
DATA_DIR = '/var/lib/pgadmin'
DEFAULT_SERVER = '0.0.0.0'
DEFAULT_SERVER_PORT = 5050
UPGRADE_CHECK_ENABLED = False
PYCONFIG
	chown "$(pgadmin_owner)" "${PGADMIN_CONFIG_FILE}" 2>/dev/null || true
fi

log "Starting pgAdmin 4 on port ${PGADMIN_PORT}..."
nohup "${PGADMIN_VENV}/bin/pgadmin4" \
	> "${PGADMIN_DATA_DIR}/server.log" 2>&1 &

for _ in $(seq 1 40); do
	if curl -sf -o /dev/null "http://127.0.0.1:${PGADMIN_PORT}/login" 2>/dev/null; then
		log "pgAdmin 4 is up. Open the 'pgAdmin 4' tab in the Ports panel to use it."
		# The login page answering is not enough: pgAdmin also has to serve its
		# built JavaScript bundles, or the browser renders a blank page with 404s
		# for style.css and vendor.*.js. Check one of them before declaring
		# victory.
		if curl -sf -o /dev/null \
			"http://127.0.0.1:${PGADMIN_PORT}/static/js/generated/vendor.react.js" 2>/dev/null; then
			exit 0
		fi
		warn "pgAdmin is running but its web assets are missing."
		warn "The browser will show a blank page. Repair it with:"
		warn "    bash .devcontainer/setup.sh"
		warn "then reload the pgAdmin tab (Cmd/Ctrl + Shift + R)."
		exit 1
	fi
	sleep 1
done

warn "pgAdmin 4 did not answer on port ${PGADMIN_PORT}."
warn "Check the log:  cat ${PGADMIN_DATA_DIR}/server.log"
