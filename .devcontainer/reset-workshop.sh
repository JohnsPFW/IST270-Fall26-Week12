#!/usr/bin/env bash
# Rebuild one workshop database from its starter script.
set -euo pipefail

case "${1:-}" in
  week10a) db=week10a; file=workshops/week10a/starter/week10a_database.sql ;;
  week10b) db=week10b; file=workshops/week10b/starter/week10b_database.sql ;;
  *) echo "Usage: bash .devcontainer/reset-workshop.sh week10a|week10b" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."
read -r -p "Erase and reload ${db}? This deletes your changes in that database. [y/N] " answer
case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac

PGPASSWORD=postgres dropdb -h localhost -U postgres --if-exists "$db"
PGPASSWORD=postgres createdb -h localhost -U postgres "$db"
PGPASSWORD=postgres psql -X -v ON_ERROR_STOP=1 -h localhost -U postgres -d "$db" -f "$file"
echo "${db} is ready. Your saved answer files were not changed."
