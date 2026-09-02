COMPOSE = docker compose --env-file srcs/.env -f srcs/docker-compose.yaml

include srcs/.env

SECRET_FILES = \
	secrets/db_password.txt \
	secrets/db_root_password.txt \
	secrets/wp_admin_password.txt \
	secrets/wp_user_password.txt

.PHONY: all prepare build up down stop start logs ps re

all: up

prepare:
	@mkdir -p "$(DATA_PATH)/mariadb" "$(DATA_PATH)/wordpress"
	@for file in $(SECRET_FILES); do \
		if [ ! -f "$$file" ]; then \
			echo "Missing secret: $$file"; \
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

