# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# User login (change this to your login)
LOGIN = mazaid

# Paths
DATA_PATH = /home/$(LOGIN)/data
MARIADB_DATA = $(DATA_PATH)/mariadb
WORDPRESS_DATA = $(DATA_PATH)/wordpress
COMPOSE_FILE = srcs/docker-compose.yml

# Default target
.DEFAULT_GOAL := help

# Phony targets (not files)
.PHONY: all build up down start stop restart clean fclean re logs ps help

##
## Available targets:
##

## all		: Create directories and start all services
all: create_dirs up

## build		: Build all Docker images
build:
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@docker compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)✓ Build complete!$(NC)"

## up		: Create and start all containers
up: create_dirs
	@echo "$(YELLOW)Starting all services...$(NC)"
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✓ All services started!$(NC)"
	@echo "$(GREEN)Access your site at: https://$(LOGIN).42.fr$(NC)"

## down		: Stop and remove all containers
down:
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✓ All services stopped!$(NC)"

## start		: Start existing containers
start:
	@echo "$(YELLOW)Starting containers...$(NC)"
	@docker compose -f $(COMPOSE_FILE) start
	@echo "$(GREEN)✓ Containers started!$(NC)"

## stop		: Stop running containers (without removing)
stop:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	@docker compose -f $(COMPOSE_FILE) stop
	@echo "$(GREEN)✓ Containers stopped!$(NC)"

## restart	: Restart all services
restart: down up

## logs		: Show logs from all containers
logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

## ps		: List all containers
ps:
	@docker compose -f $(COMPOSE_FILE) ps

## clean		: Stop containers and remove volumes
clean: down
	@echo "$(YELLOW)Removing Docker volumes...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down -v
	@echo "$(GREEN)✓ Volumes removed!$(NC)"

## fclean	: Full cleanup (containers, volumes, images, data directories)
fclean: clean
	@echo "$(YELLOW)Removing Docker images...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(YELLOW)Removing data directories...$(NC)"
	@sudo rm -rf $(DATA_PATH)
	@echo "$(YELLOW)Pruning Docker system...$(NC)"
	@docker system prune -af --volumes
	@echo "$(GREEN)✓ Full cleanup complete!$(NC)"

## re		: Full rebuild (fclean + all)
re: fclean all

## create_dirs	: Create data directories if they don't exist
create_dirs:
	@if [ ! -d "$(MARIADB_DATA)" ]; then \
		echo "$(YELLOW)Creating MariaDB data directory...$(NC)"; \
		sudo mkdir -p $(MARIADB_DATA); \
		sudo chown -R $(USER):$(USER) $(DATA_PATH); \
	fi
	@if [ ! -d "$(WORDPRESS_DATA)" ]; then \
		echo "$(YELLOW)Creating WordPress data directory...$(NC)"; \
		sudo mkdir -p $(WORDPRESS_DATA); \
		sudo chown -R $(USER):$(USER) $(DATA_PATH); \
	fi

## help		: Show this help message
help:
	@echo "$(GREEN)Inception Project - Available Commands:$(NC)"
	@echo ""
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
	@echo ""
