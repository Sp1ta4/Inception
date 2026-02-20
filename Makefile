NAME = inception

DOCKER_COMPOSE = docker compose
COMPOSE_FILE = ./srcs/docker-compose.yml
ENV_FILE = ./srcs/secrets/.env

include $(ENV_FILE)
export

all: setup volumes up

setup:
	@echo "Setting up data directories..."
	@sudo mkdir -p $(DATA_PATH)/wordpress
	@sudo mkdir -p $(DATA_PATH)/mariadb
	@sudo chown -R $(USER):$(USER) $(DATA_PATH)
	@sudo chmod -R 755 $(DATA_PATH)
	@echo "Data directories created at $(DATA_PATH)"

volumes:
	@echo "Creating Docker volumes..."
	@docker volume create wordpress_data 2>/dev/null || true
	@docker volume create mariadb_data 2>/dev/null || true
	@echo "Fixing volume permissions..."
	@sudo chmod -R 755 /var/lib/docker/volumes/mariadb_data || true
	@sudo chmod -R 755 /var/lib/docker/volumes/wordpress_data || true

up:
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
	@echo ""
	@echo "=== Volume Permissions ==="
	@sudo ls -la /var/lib/docker/volumes/ | grep -E "mariadb|wordpress" || true

clean: down
	@echo "Cleaning Docker system..."
	@docker system prune -af

fclean:
	@echo "=== Full Clean ==="
	@echo "Stopping containers..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down -v 2>/dev/null || true
	@docker stop nginx wordpress mariadb 2>/dev/null || true
	@docker rm -f nginx wordpress mariadb 2>/dev/null || true
	@echo "Removing Docker volumes..."
	@docker volume rm wordpress_data mariadb_data 2>/dev/null || true
	@echo "Removing networks..."
	@docker network rm inception 2>/dev/null || true
	@echo "Cleaning Docker system..."
	@docker system prune -af --volumes
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_PATH)/wordpress 2>/dev/null || true
	@sudo rm -rf $(DATA_PATH)/mariadb 2>/dev/null || true
	@echo "Cleaning Docker volume metadata..."
	@sudo rm -rf /var/lib/docker/volumes/mariadb_data 2>/dev/null || true
	@sudo rm -rf /var/lib/docker/volumes/wordpress_data 2>/dev/null || true
	@echo "Full clean completed!"

re: fclean all

config:
	@echo "Checking Docker Compose configuration..."
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) config

test:
	@echo "Testing services..."
	@echo "- Checking Nginx:"
	@curl -k -I https://$(DOMAIN_NAME) 2>/dev/null | head -1 || echo "Nginx not responding"
	@echo "- Checking MariaDB:"
	@docker exec mariadb mysqladmin ping -h localhost --silent && echo "MariaDB OK" || echo "MariaDB not responding"
	@echo "- Checking WordPress:"
	@docker exec wordpress wp core version --allow-root 2>/dev/null || echo "WordPress not ready"

.PHONY: all setup volumes up down stop start restart logs logs-nginx logs-wordpress logs-mariadb \
        status clean fclean re config test