#!/usr/bin/env bash
# =============================================================================
# IST 270 — create YOUR OWN pgAdmin 4 account
#
# This creates a personal pgAdmin login for you and registers the IST 270
# PostgreSQL server under it, so when you sign in you land on a working
# connection instead of having to type the host, port, username and password
# by hand.
#
# Run it once, in the Codespace terminal:
#
#     bash .devcontainer/create-my-pgadmin-account.sh
#
# You will be asked for:
#   * an email address - any address you like. It is only a login name.
#   * a password - at least 6 characters. Pick one you will remember.
#
# If you already have an account, running it again lets you reset your
# password instead of creating a second account.
#
# After it finishes, open pgAdmin and sign in with what you just chose.
#
# Notes:
#   * The PostgreSQL connection itself is shared with the class template:
#     host localhost, port 5432, user postgres, password postgres. That is
#     your own database inside your own Codespace.
#   * This script only touches your own Codespace. It does not touch anyone
#     else's.
#   * It is safe to run more than once.
# =============================================================================

set -uo pipefail

PGADMIN_VENV="/opt/pgadmin"
PGADMIN_DATA_DIR="/var/lib/pgadmin"
PGADMIN_CONFIG_FILE="${PGADMIN_DATA_DIR}/config_custom.py"
PGADMIN_DB="${PGADMIN_DATA_DIR}/pgadmin4.db"
MIN_PASSWORD_LENGTH=6

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="${SCRIPT_DIR}/pgadmin-servers.json"

log()  { printf '\033[1;36m[IST 270]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[IST 270]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[IST 270] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# --- Preflight ----------------------------------------------------------------
if [ ! -x "${PGADMIN_VENV}/bin/pgadmin4-cli" ]; then
	fail "pgAdmin 4 is not installed yet. Run: bash .devcontainer/setup.sh"
fi

if [ ! -f "${SERVERS_FILE}" ]; then
	fail "Cannot find ${SERVERS_FILE}."
fi

if [ ! -f "${PGADMIN_DB}" ]; then
	fail "The pgAdmin configuration database is missing. Run: bash .devcontainer/setup.sh"
fi

# Point pgAdmin at the same configuration database this environment uses.
# Only export the path when the file really exists: pgAdmin aborts with a
# hard FileNotFoundError if CONFIG_DISTRO_FILE_PATH points at a missing file.
if [ -f "${PGADMIN_CONFIG_FILE}" ]; then
	export CONFIG_DISTRO_FILE_PATH="${PGADMIN_CONFIG_FILE}"
fi

# The configuration database is normally owned by the student account, so the
# CLI can write to it without elevation. If a setup run left it owned by root,
# fall back to sudo rather than failing with a confusing SQLite error.
if [ -w "${PGADMIN_DB}" ]; then
	cli() { "${PGADMIN_VENV}/bin/pgadmin4-cli" "$@"; }
else
	warn "The pgAdmin configuration database needs elevated access; using sudo."
	cli() { sudo "${PGADMIN_VENV}/bin/pgadmin4-cli" "$@"; }
fi

# --- Ask for the email address -------------------------------------------------
DEFAULT_EMAIL=""
GIT_EMAIL="$(git config --get user.email 2>/dev/null || true)"
if [ -n "${GIT_EMAIL}" ] && printf '%s' "${GIT_EMAIL}" | grep -q '@'; then
	DEFAULT_EMAIL="${GIT_EMAIL}"
fi

printf '\n'
log "Let's set up your own pgAdmin 4 account."
printf '\n'
printf '  The email address is only a login name for pgAdmin. It does not have\n'
printf '  to be a real address, and nothing is sent to it.\n\n'

if [ -n "${DEFAULT_EMAIL}" ]; then
	printf '  Email address [%s]: ' "${DEFAULT_EMAIL}"
else
	printf '  Email address: '
fi
read -r EMAIL
[ -n "${EMAIL}" ] || EMAIL="${DEFAULT_EMAIL}"

if [ -z "${EMAIL}" ]; then
	fail "An email address is required."
fi

# --- Does this account already exist? -------------------------------------------
# pgadmin4-cli prints a small table per user: a Username row, an Email row and
# a role row. The email appears twice, so the role is read from the row that
# follows the email.
existing_role() {
	cli get-users 2>/dev/null \
		| awk -F'|' -v email="${EMAIL}" '
			$2 ~ /Email/ && index($0, email) { found = 1; next }
			found && $2 ~ /role/ { gsub(/[ \t]/, "", $3); print $3; exit }
		'
}

EXISTING_ROLE="$(existing_role)"

# --- Existing account: offer a password reset -----------------------------------
if [ -n "${EXISTING_ROLE}" ]; then
	printf '\n'
	warn "You already have an account: ${EMAIL} (role: ${EXISTING_ROLE})."
	log "Nothing will be overwritten, and no second account will be created."
	printf '\n'
	printf '  Reset your password? [y/N]: '
	read -r RESET
	case "${RESET}" in
		[yY]|[yY][eE][sS]) ;;
		*)
			printf '\n'
			log "Just sign in to pgAdmin with that email and your existing password."
			log "If you have forgotten it, answer y here to set a new one."
			printf '\n'
			exit 0
			;;
	esac

	printf '  New password (at least %d characters): ' "${MIN_PASSWORD_LENGTH}"
	read -r -s NEW_PASSWORD
	printf '\n'
	printf '  Type the password again: '
	read -r -s NEW_PASSWORD2
	printf '\n'

	if [ "${#NEW_PASSWORD}" -lt "${MIN_PASSWORD_LENGTH}" ]; then
		fail "That password is too short. It needs at least ${MIN_PASSWORD_LENGTH} characters."
	fi
	if [ "${NEW_PASSWORD}" != "${NEW_PASSWORD2}" ]; then
		fail "The two passwords did not match. Run the command again."
	fi

	printf '\n'
	log "Resetting your password..."
	# pgadmin4-cli's update-user requires --role as well as --password;
	# without it the command fails with "KeyError: 'role'".
	if ! cli update-user "${EMAIL}" --password "${NEW_PASSWORD}" --role "${EXISTING_ROLE}" >/dev/null 2>&1; then
		fail "Could not reset the password. Ask the instructor for help."
	fi
	log "Password reset."

	printf '\n'
	printf '  ---------------------------------------------------------------\n'
	printf '   Your pgAdmin password is now the one you just chose.\n'
	printf '\n'
	printf '   Sign in at the pgAdmin tab in the Ports panel with:\n'
	printf '   Email: %s\n' "${EMAIL}"
	printf '  ---------------------------------------------------------------\n'
	printf '\n'
	exit 0
fi

# --- New account: ask for a password --------------------------------------------
printf '  Password (at least %d characters): ' "${MIN_PASSWORD_LENGTH}"
read -r -s PASSWORD
printf '\n'

if [ "${#PASSWORD}" -lt "${MIN_PASSWORD_LENGTH}" ]; then
	fail "That password is too short. It needs at least ${MIN_PASSWORD_LENGTH} characters."
fi

printf '  Type the password again: '
read -r -s PASSWORD2
printf '\n'

if [ "${PASSWORD}" != "${PASSWORD2}" ]; then
	fail "The two passwords did not match. Run the command again."
fi

printf '\n'
log "Creating your pgAdmin account..."

if ! cli add-user "${EMAIL}" "${PASSWORD}" --role "User" >/dev/null 2>&1; then
	fail "pgAdmin would not create the account. Check the email and password, then try again."
fi
log "Account created."

# --- Register the IST 270 PostgreSQL server for this account ---------------------
# The server list is stored per user in pgAdmin's configuration database, so
# this has to be done for the new account specifically.
log "Registering the IST 270 PostgreSQL server..."

if ! cli load-servers "${SERVERS_FILE}" --user "${EMAIL}" >/dev/null 2>&1; then
	warn "Could not register the server automatically."
	warn "Add it by hand: right-click 'Servers' > Add Server, then use"
	warn "    Name: IST 270 Local PostgreSQL"
	warn "    Host: localhost    Port: 5432"
	warn "    Username: postgres    Password: postgres"
	warn "    Maintenance database: postgres"
	printf '\n'
	exit 0
fi

# --- Verify ----------------------------------------------------------------------
VERIFY_OUT="$(mktemp)"
if cli dump-servers "${VERIFY_OUT}" --user "${EMAIL}" >/dev/null 2>&1 \
   && grep -q "IST 270 Local PostgreSQL" "${VERIFY_OUT}"; then
	log "Server registered."
else
	warn "Could not confirm the server registration."
	warn "Add it by hand using the connection details in the README."
fi
rm -f "${VERIFY_OUT}"

printf '\n'
printf '  ---------------------------------------------------------------\n'
printf '   Your pgAdmin account is ready.\n'
printf '\n'
printf '   Email    : %s\n' "${EMAIL}"
printf '   Password : the one you just chose\n'
printf '\n'
printf '   Sign in at the pgAdmin tab in the Ports panel.\n'
printf '\n'
printf '   The "IST 270 Local PostgreSQL" server is already in your\n'
printf '   object browser - expand it and you are connected.\n'
printf '  ---------------------------------------------------------------\n'
printf '\n'
log "If you were already signed in as student@ist270.edu, sign out first"
log "(Log Out, bottom-left) and then sign in with your own account."
printf '\n'
