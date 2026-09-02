COMPOSE := docker compose --env-file srcs/.env -f srcs/docker-compose.yaml

SECRET_FILES := \
	secrets/db_password.txt \
	secrets/db_root_password.txt \
	secrets/wp_admin_password.txt \
	secrets/wp_user_password.txt

.PHONY: all prepare build up down stop start logs ps re

all: up

prepare:
	@for file in $(SECRET_FILES); do \
		if [ ! -s "$$file" ]; then \
			echo "Missing or empty secret: $$file"; \
			exit 1; \
		fi; \
	done

build: prepare
	$(COMPOSE) build

up: prepare
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

re: down up
