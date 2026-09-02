#!/bin/sh

set -eu

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
CONFIG_FLAG="$DATADIR/.inception_configured"

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
MYSQL_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

# Runtime directories + cleanup
mkdir -p "$RUNDIR" "$DATADIR"

rm -f \
    "$RUNDIR/mysqld.sock" \
    "$RUNDIR/mysqld.pid"

chown -R mysql:mysql "$RUNDIR" "$DATADIR"

# 1. Initialize MariaDB's own system tables
if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db \
        --user=mysql \
        --datadir="$DATADIR" \
        --auth-root-authentication-method=normal \
        --skip-test-db
fi

# 2. Initialize OUR Inception database/users
if [ ! -f "$CONFIG_FLAG" ]; then
    echo "Configuring Inception database..."

    mariadbd \
        --bootstrap \
        --user=mysql \
        --datadir="$DATADIR" \
        --skip-networking <<EOF

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
