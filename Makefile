NAME = inception

DOCKER_COMPOSE = docker compose
COMPOSE_FILE = ./srcs/docker-compose.yml
ENV_FILE = ./srcs/secrets/.env

include $(ENV_FILE)
export

all: setup up

setup:
	@echo "Setting up data directories..."
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@chmod 755 $(DATA_PATH)
	@chmod 755 $(DATA_PATH)/wordpress
	@chmod 755 $(DATA_PATH)/mariadb
	@chown -R $(USER):$(USER) $(DATA_PATH)
	@echo "Data directories created at $(DATA_PATH)"

up: setup
	@echo "Starting containers..."
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build --remove-orphans

down:
	@echo "Stopping containers..."
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down

stop:
	@echo "Stopping containers (without removing)..."
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) stop

start:
	@echo "Starting stopped containers..."
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) start

restart: down up

logs:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f

logs-nginx:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f nginx

logs-wordpress:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f wordpress

logs-mariadb:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f mariadb

status:
	@echo "=== Docker Containers ==="
	@docker ps -a
	@echo ""
	@echo "=== Docker Volumes ==="
	@docker volume ls
	@echo ""
	@echo "=== Data Directories ==="
	@if [ -d "$(DATA_PATH)" ]; then \
		ls -lah $(DATA_PATH); \
	else \
		echo "Data directory does not exist: $(DATA_PATH)"; \
	fi

clean: down
	@echo "Cleaning Docker system..."
	@docker system prune -af

clean-volumes:
	@echo "Removing volumes..."
	@docker volume rm wordpress_data mariadb_data 2>/dev/null || true

clean-data:
	@echo "Removing data from $(DATA_PATH)..."
	@if [ -d "$(DATA_PATH)/wordpress" ]; then \
		rm -rf $(DATA_PATH)/wordpress/*; \
	fi
	@if [ -d "$(DATA_PATH)/mariadb" ]; then \
		rm -rf $(DATA_PATH)/mariadb/*; \
	fi
	@echo "Data directories cleaned"

fclean: down clean-volumes clean-data
	@echo "Full clean: removing system and data..."
	@docker system prune -af --volumes

re: fclean all

config:
	@echo "Checking Docker Compose configuration..."
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) config | grep -A5 device

test:
	@echo "Testing services..."
	@echo "- Checking Nginx:"
	@curl -k -I https://$(DOMAIN_NAME) 2>/dev/null | head -1 || echo "Nginx not responding"
	@echo "- Checking MariaDB:"
	@docker exec mariadb mysqladmin ping -h localhost --silent && echo "MariaDB OK" || echo "MariaDB not responding"
	@echo "- Checking WordPress:"
	@docker exec wordpress wp core version --allow-root 2>/dev/null || echo "WordPress not ready"

.PHONY: all setup up down stop start restart logs logs-nginx logs-wordpress logs-mariadb \
        status clean clean-volumes clean-data fclean re config test