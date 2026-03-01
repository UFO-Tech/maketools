setup:
	@test -f .env || cp .env.dist .env

PROJECT_NAME ?= $(shell \
	grep -hE '^[[:space:]]*PROJECT_NAME=' .env.local .env 2>/dev/null \
	| tail -n 1 \
	| cut -d '=' -f2- \
)

DOCKER_COMPOSE = docker-compose
BASH_PHP = docker exec -it php_$(PROJECT_NAME) /bin/bash
BASH_NGINX = docker exec -it nginx_$(PROJECT_NAME) /bin/bash
EXEC_PHP = $(BASH_PHP) -c
EXEC_NGINX = $(BASH_NGINX) -c

# Docker Compose Commands
up: ## docker-compose up
	$(DOCKER_COMPOSE) up

up-d: ## docker-compose up -d
	$(DOCKER_COMPOSE) up -d

up-b:
	$(DOCKER_COMPOSE) up --build

up-dr: ## docker-compose up -d --force-recreate
	$(DOCKER_COMPOSE) up -d --force-recreate

up-r:
	$(DOCKER_COMPOSE) up --force-recreate

down:
	$(DOCKER_COMPOSE) down --remove-orphans

php-run: EXEC = "$(filter-out $@,$(MAKECMDGOALS))"
php-run:
	@if [ -z "$(EXEC)" ]; then \
		echo "Error: No arguments provided for 'run' command."; \
		exit 1; \
	fi
	$(EXEC_PHP) "$(EXEC)"


php-exec:
	$(EXEC_PHP) "echo -e '\033[32m'; /bin/bash"

nginx-exec:
	$(EXEC_NGINX) "echo -e '\033[32m'; /bin/bash"
