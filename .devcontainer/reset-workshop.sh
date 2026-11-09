#!/usr/bin/env bash
# Rebuild one workshop database from its starter script.
set -euo pipefail

case "${1:-}" in
  week12a) db=week12a; file=workshops/week12a/starter/week12a_database.sql ;;
  week12b) db=week12b; file=workshops/week12b/starter/week12b_database.sql ;;
  *) echo "Usage: bash .devcontainer/reset-workshop.sh week12a|week12b" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."
read -r -p "Erase and reload ${db}? This deletes your changes in that database. [y/N] " answer
case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac

PGPASSWORD=postgres dropdb -h localhost -U postgres --if-exists "$db"
PGPASSWORD=postgres createdb -h localhost -U postgres "$db"
PGPASSWORD=postgres psql -X -v ON_ERROR_STOP=1 -h localhost -U postgres -d "$db" -f "$file"
echo "${db} is ready. Your saved answer files were not changed."
