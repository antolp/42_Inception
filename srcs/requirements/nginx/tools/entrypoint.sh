#!/bin/sh

set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"

SSL_DIR="/etc/nginx/ssl"
mkdir -p "$SSL_DIR"

if [ ! -f "$SSL_DIR/nginx.crt" ] || [ ! -f "$SSL_DIR/nginx.key" ]; then
	echo "Generating self-signed TLS certificate for ${DOMAIN_NAME}..."
	openssl req \
		-x509 \
		-nodes \
		-newkey rsa:2048 \
		-days 365 \
		-keyout "$SSL_DIR/nginx.key" \
		-out "$SSL_DIR/nginx.crt" \
		-subj "/CN=${DOMAIN_NAME}"

	chmod 600 "$SSL_DIR/nginx.key"
	chmod 644 "$SSL_DIR/nginx.crt"
fi

sed "s|__DOMAIN_NAME__|${DOMAIN_NAME}|g" \
	/etc/nginx/nginx.conf.tpl \
	> /etc/nginx/nginx.conf

nginx -t

echo "Starting NGINX..."
exec "$@"

