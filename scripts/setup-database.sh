#!/usr/bin/env bash
# =====================================================================
# setup-database.sh – legt DB + User an und importiert sql/*.sql
#
#   DB_PASS='geheim' ./scripts/setup-database.sh
#
# Voraussetzung: MariaDB läuft lokal, Aufruf mit root-Rechten (sudo),
# damit "mariadb" sich per unix_socket als root anmelden kann.
# Die SQL-Dateien nutzen "CREATE TABLE IF NOT EXISTS" -> mehrfach
# ausführbar, ändert aber KEINE bestehenden Tabellen (Migrationen
# bei Updates siehe docs/UPDATES.md).
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_NAME="${DB_NAME:-qbox}"
DB_USER="${DB_USER:-fivem}"
DB_HOST="${DB_HOST:-127.0.0.1}"
: "${DB_PASS:?Bitte DB_PASS setzen, z.B. DB_PASS='...' $0}"

MYSQL=(mariadb)
command -v mariadb >/dev/null || MYSQL=(mysql)

"${MYSQL[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS';
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'$DB_HOST';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQL

for f in "$ROOT"/sql/*.sql; do
  echo ">> Import $(basename "$f")"
  "${MYSQL[@]}" "$DB_NAME" < "$f"
done

echo
echo "Fertig. In server-data/secrets.cfg eintragen:"
echo "set mysql_connection_string \"mysql://$DB_USER:<PASSWORT>@$DB_HOST:3306/$DB_NAME?charset=utf8mb4\""
