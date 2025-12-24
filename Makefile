NAME = inception

DOCKER_COMPOSE = docker-compose
COMPOSE_FILE = docker-compose.yml

all: up

up:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d --build

down:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down

stop:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) stop

start:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) start

restart:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) restart

clean: down
	docker system prune -af

fclean: down
	docker system prune -af
	docker volume prune -f

re: fclean up

.PHONY: all up down stop start restart clean fclean re
