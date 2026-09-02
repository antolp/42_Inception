#!/bin/sh

set -eu

WP_PATH="/var/www/html"

for secret in \
	/run/secrets/db_password \
	/run/secrets/wp_admin_password \
	/run/secrets/wp_user_password
do
	if [ ! -r "$secret" ]; then
		echo "Missing or unreadable secret: $secret" >&2
		exit 1
	fi
done

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

mkdir -p "$WP_PATH" /run/php

#depends_on from compose gives startup order, not readyness
#verify that the database, database user, and credentials are before proceeding
attempt=1
while [ "$attempt" -le 30 ]; do
	if mariadb \
		--host="$MYSQL_HOST" \
		--user="$MYSQL_USER" \
		--password="$MYSQL_PASSWORD" \
		"$MYSQL_DATABASE" \
		--execute="SELECT 1" >/dev/null 2>&1
	then
		break
	fi

	if [ "$attempt" -eq 30 ]; then
		echo "MariaDB did not become ready after 60 seconds." >&2
		exit 1
	fi

	echo "Waiting for MariaDB... ($attempt/30)"
	attempt=$((attempt + 1))
	sleep 2
done

# The volume may be empty on the first run.
if [ ! -f "$WP_PATH/wp-load.php" ]; then
	echo "Downloading WordPress core..."
	wp core download \
		--allow-root \
		--force \
		--path="$WP_PATH"
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
	echo "Creating wp-config.php..."
	wp config create \
		--allow-root \
		--path="$WP_PATH" \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$MYSQL_PASSWORD" \
		--dbhost="${MYSQL_HOST}:3306"
fi

if ! wp core is-installed --allow-root --path="$WP_PATH" >/dev/null 2>&1; then
	echo "Installing WordPress..."
	wp core install \
		--allow-root \
		--path="$WP_PATH" \
		--url="https://${DOMAIN_NAME}" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email
fi

if ! wp user get "$WP_USER_NAME" --allow-root --path="$WP_PATH" >/dev/null 2>&1; then
	echo "Creating second WordPress user..."
	wp user create \
		"$WP_USER_NAME" \
		"$WP_USER_EMAIL" \
		--allow-root \
		--path="$WP_PATH" \
		--role=author \
		--user_pass="$WP_USER_PASSWORD"
fi

chown -R www-data:www-data "$WP_PATH"
find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

echo "Starting PHP-FPM..."
exec "$@"

