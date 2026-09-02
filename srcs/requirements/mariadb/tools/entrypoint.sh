#!/bin/sh

set -eu

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
CONFIG_FLAG="$DATADIR/.inception_configured"

for secret in /run/secrets/db_password /run/secrets/db_root_password; do
	if [ ! -r "$secret" ]; then
		echo "Missing or unreadable secret: $secret" >&2
		exit 1
	fi
done

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
MYSQL_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

mkdir -p "$RUNDIR" "$DATADIR"

# Runtime files are disposable. Remove leftovers from an unclean shutdown.
rm -f "$RUNDIR/mysqld.sock" "$RUNDIR/mysqld.pid"

# The volume is mounted at runtime, so fix its ownership at runtime too.
chown -R mysql:mysql "$RUNDIR" "$DATADIR"

# Stage 1: initialize MariaDB's own system tables once.
if [ ! -d "$DATADIR/mysql" ]; then
	echo "Initializing MariaDB data directory..."
	mariadb-install-db \
		--user=mysql \
		--datadir="$DATADIR" \
		--auth-root-authentication-method=normal \
		--skip-test-db
fi

# Stage 2: initialize the Inception database and account once.
if [ ! -f "$CONFIG_FLAG" ]; then
	echo "Configuring Inception database..."

mariadbd \
    --bootstrap \
    --user=mysql \
    --datadir="$DATADIR" \
    --skip-networking <<EOF

FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
IDENTIFIED BY '${MYSQL_PASSWORD}';

ALTER USER '${MYSQL_USER}'@'%'
IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES
ON \`${MYSQL_DATABASE}\`.*
TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

	touch "$CONFIG_FLAG"
	chown mysql:mysql "$CONFIG_FLAG"
fi

echo "Starting MariaDB..."
exec "$@"

