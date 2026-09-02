FROM debian:12

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		nginx \
		openssl \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf.tpl /etc/nginx/nginx.conf.tpl
COPY tools/entrypoint.sh /usr/local/bin/nginx-entrypoint.sh

RUN chmod +x /usr/local/bin/nginx-entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

