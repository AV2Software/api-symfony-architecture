#!/bin/bash

DOCKER_WEB = app-web
DOCKER_BE = app-be
DOCKER_DB = app-db
UID = $(shell id -u)

help: ## Show this help message
	@echo 'usage: make [target]'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

start: ## Start the containers
	docker network create app-network || true
	U_ID=${UID} docker-compose up -d

stop: ## Stop the containers
	U_ID=${UID} docker-compose stop

restart: ## Restart the containers
	$(MAKE) stop && $(MAKE) start

build: ## Rebuilds all the containers
	U_ID=${UID} docker-compose build

prepare: ## Runs backend commands
	$(MAKE) composer-install

# Backend commands
composer-install: ## Installs composer dependencies
	U_ID=${UID} docker exec --user ${UID} -it ${DOCKER_BE} composer clearcache
	U_ID=${UID} docker exec --user ${UID} -it ${DOCKER_BE} composer install --no-plugins --no-scripts --no-interaction --optimize-autoloader

be-logs: ## Tails the Symfony dev log
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} tail -f var/log/dev.log
# End backend commands

web-logs-error: ## 
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_WEB} tail -f var/log/nginx/symfony_error.log
# End backend commands

web-logs-access: ## 
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_WEB} tail -f var/log/nginx/symfony_access.log
# End backend commands

generate-cron: ## create cron
	crontab crontab
# End cron commands

ssh-be: ## ssh's into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} bash

ssh-web: ## ssh's into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_WEB} bash

ssh-db: ## ssh's into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_DB} bash

ssh-psql: ## ssh's into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_DB} psql -U postgres

generate-var: ## Generate folder cache
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} mkdir -m 777 -p var/cache/
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} mkdir -m 777 -p var/log/

generate-ssh-keys: ## Generates SSH keys for JWT library
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} mkdir -m 777 -p config/jwt
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} openssl genrsa -passout pass:e21eb5b98e463808495942f22b277de1 -out config/jwt/private.pem -aes256 4096
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} openssl rsa -pubout -passin pass:e21eb5b98e463808495942f22b277de1 -in config/jwt/private.pem -out config/jwt/public.pem

code-style: ## Runs php-cs to fix code styling following Symfony rules
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} php-cs-fixer fix src --rules=@Symfony
