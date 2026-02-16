# Developer Documentation

This document provides technical information for developers who need to set up, modify, or extend the Inception project.

## Environment Setup from Scratch

### Prerequisites

Install the following software on your system:

**Required:**
- Docker Engine 20.10 or higher
- Docker Compose 1.29 or higher (or Docker Compose v2)
- GNU Make
- Git

**Optional but recommended:**
- curl (for testing)
- openssl (for manual certificate generation if needed)
- text editor with YAML/Dockerfile syntax highlighting

**System requirements:**
- Linux operating system (tested on Ubuntu 20.04/22.04)
- Minimum 2GB RAM
- Minimum 10GB free disk space
- User must be in the docker group to run Docker without sudo

### Adding User to Docker Group

If you haven't already, add your user to the docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

Verify Docker works without sudo:
```bash
docker run hello-world
```

### Project Structure
```
Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── docker-compose.yml
    ├── .env (created from secrets/.env)
    ├── secrets/
    │   └── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       ├── certs.sh
        │       └── start.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf (PHP-FPM pool config)
        │   └── tools/
        │       └── wp_setup.sh
        └── mariadb/
            ├── Dockerfile
            └── tools/
                └── init_db.sh
```

### Configuration Files

**Environment Variables (`srcs/secrets/.env`):**

Create this file with the following structure:
```env
# Host data storage path
DATA_PATH=/home/your_username/data

# Domain name
DOMAIN_NAME=your_username.42.fr

# MariaDB configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=secure_random_password_here
MYSQL_ROOT_PASSWORD=another_secure_password

# WordPress admin user
WP_TITLE=My WordPress Site
WP_ADMIN_USER=siteowner
WP_ADMIN_PASSWORD=admin_secure_password
WP_ADMIN_EMAIL=admin@example.com

# WordPress additional user
WP_USER=editor
WP_USER_EMAIL=editor@example.com
WP_USER_PASSWORD=editor_password
```

**Important notes:**
- Replace `your_username` with your actual system username
- Use strong, unique passwords (minimum 12 characters)
- The admin username must NOT contain "admin" or "administrator"
- This file must be git-ignored

**Hosts File:**

Add your domain to `/etc/hosts`:
```bash
echo "127.0.0.1    your_username.42.fr" | sudo tee -a /etc/hosts
```

### Secrets Management

The `.env` file contains sensitive information and must never be committed to version control.

Ensure `.gitignore` includes:
```
srcs/secrets/.env
.env
```

For production deployments, consider using Docker secrets:
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
  
services:
  mariadb:
    secrets:
      - db_password
```

## Building and Launching

### Using the Makefile

The Makefile provides convenient commands for managing the project:

**Build and start everything:**
```bash
make
```

This runs `make setup` followed by `make up`.

**Setup data directories only:**
```bash
make setup
```

Creates directories at `${DATA_PATH}/wordpress` and `${DATA_PATH}/mariadb` with correct permissions.

**Start containers:**
```bash
make up
```

Builds images if needed and starts all containers in detached mode.

**Stop containers:**
```bash
make down
```

Stops and removes containers but preserves volumes and data.

**View logs:**
```bash
make logs              # All services
make logs-nginx        # NGINX only
make logs-wordpress    # WordPress only
make logs-mariadb      # MariaDB only
```

**Check status:**
```bash
make status
```

Shows containers, volumes, and data directories.

**Clean Docker resources:**
```bash
make clean      # Remove containers and prune system
make fclean     # Complete cleanup including data
make re         # Rebuild from scratch (fclean + all)
```

**Test services:**
```bash
make test
```

Runs basic health checks on all services.

### Using Docker Compose Directly

If you need more control, use docker-compose commands directly:
```bash
# Build images
docker-compose -f srcs/docker-compose.yml --env-file srcs/secrets/.env build

# Start in foreground (see logs in real-time)
docker-compose -f srcs/docker-compose.yml --env-file srcs/secrets/.env up

# Start in background
docker-compose -f srcs/docker-compose.yml --env-file srcs/secrets/.env up -d

# Stop
docker-compose -f srcs/docker-compose.yml --env-file srcs/secrets/.env down

# View logs
docker-compose -f srcs/docker-compose.yml --env-file srcs/secrets/.env logs -f

# Rebuild specific service
docker-compose -f srcs/docker-compose.yml --env-file srcs/secrets/.env build --no-cache nginx
```

## Container Management

### Listing Containers
```bash
# All containers (running and stopped)
docker ps -a

# Only running
docker ps

# With custom format
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Executing Commands in Containers
```bash
# Interactive shell
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Single command
docker exec nginx nginx -t                    # Test NGINX config
docker exec wordpress wp --info --allow-root  # WordPress info
docker exec mariadb mysql -V                  # MariaDB version
```

### Inspecting Containers
```bash
# Full container details
docker inspect nginx

# Specific information
docker inspect -f '{{.State.Status}}' nginx
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' wordpress
docker inspect -f '{{.Config.Env}}' mariadb
```

### Container Logs
```bash
# Follow logs
docker logs -f nginx

# Last 100 lines
docker logs --tail 100 wordpress

# Since specific time
docker logs --since 30m mariadb

# With timestamps
docker logs -t nginx
```

### Restarting Containers
```bash
# Restart one
docker restart nginx

# Restart all
docker restart nginx wordpress mariadb

# Stop and start (vs restart)
docker stop nginx && docker start nginx
```

## Volume Management

### Listing Volumes
```bash
# All volumes
docker volume ls

# Filter by name
docker volume ls | grep inception
```

### Inspecting Volumes
```bash
# Full details
docker volume inspect wordpress_data

# Check mount point
docker volume inspect -f '{{.Mountpoint}}' wordpress_data

# Check driver options
docker volume inspect -f '{{.Options}}' mariadb_data
```

### Volume Data Location

Volumes are configured to store data at:
```
${DATA_PATH}/wordpress/  → WordPress files
${DATA_PATH}/mariadb/    → Database files
```

Where `${DATA_PATH}` is defined in `.env`, typically `/home/username/data`.

### Accessing Volume Data
```bash
# List WordPress files
ls -lah ~/data/wordpress/

# List database files
ls -lah ~/data/mariadb/

# Check disk usage
du -sh ~/data/wordpress/
du -sh ~/data/mariadb/
```

### Backing Up Volumes
```bash
# Create backup
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz -C ~/data/wordpress .
tar -czf mariadb-backup-$(date +%Y%m%d).tar.gz -C ~/data/mariadb .

# Restore from backup
tar -xzf wordpress-backup-20240216.tar.gz -C ~/data/wordpress/
```

### Removing Volumes
```bash
# Remove specific volume
docker volume rm wordpress_data

# Remove all unused volumes
docker volume prune

# Remove volumes when stopping
docker-compose down -v
```

**Warning:** Removing volumes deletes all data permanently.

## Network Management

### Inspecting the Network
```bash
# List all networks
docker network ls

# Inspect inception network
docker network inspect inception

# See connected containers
docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' inception
```

### Testing Container Connectivity
```bash
# From NGINX to WordPress
docker exec nginx ping -c 3 wordpress

# From WordPress to MariaDB
docker exec wordpress ping -c 3 mariadb

# Check if port is open
docker exec nginx nc -zv wordpress 9000
docker exec wordpress nc -zv mariadb 3306
```

### Network Troubleshooting
```bash
# Check listening ports in container
docker exec wordpress ss -tuln

# Test HTTP connection
docker exec nginx curl -I http://wordpress:9000

# DNS resolution
docker exec nginx nslookup wordpress
```

## Image Management

### Listing Images
```bash
# All images
docker images

# Filter by repository
docker images | grep inception
```

### Building Images
```bash
# Build all images
docker-compose -f srcs/docker-compose.yml build

# Build specific image
docker-compose -f srcs/docker-compose.yml build nginx

# Build without cache
docker-compose -f srcs/docker-compose.yml build --no-cache

# Build with progress
docker-compose -f srcs/docker-compose.yml build --progress=plain
```

### Removing Images
```bash
# Remove specific image
docker rmi inception-nginx

# Remove all unused images
docker image prune -a

# Remove all project images
docker images | grep inception | awk '{print $3}' | xargs docker rmi
```

## Data Persistence

### How Data Persists

The project uses named Docker volumes with custom storage locations:
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/wordpress
```

This creates a Docker-managed volume that physically stores data at the specified path on the host.

**Why this approach?**
- Satisfies the requirement to store data in `/home/login/data`
- Volumes appear in `docker volume ls` (not true with bind mounts)
- Docker manages the volume lifecycle
- Data persists when containers are removed
- Can be backed up from the host filesystem

### Data Flow

**WordPress uploads:**
```
User uploads image → NGINX → WordPress container → PHP processes file
→ Saves to /var/www/html/wp-content/uploads/
→ Actually stored at ~/data/wordpress/wp-content/uploads/ (via volume)
```

**Database writes:**
```
WordPress saves post → MariaDB container → Database writes to /var/lib/mysql/
→ Actually stored at ~/data/mariadb/ (via volume)
```

### Verifying Data Persistence
```bash
# Create test post in WordPress admin panel

# Stop containers
make down

# Check data still exists
ls ~/data/wordpress/wp-content/uploads/
ls ~/data/mariadb/wordpress/

# Start containers
make up

# Test post should still be visible
```

## Development Workflow

### Making Changes to Dockerfiles

1. Edit the Dockerfile
2. Rebuild the specific service:
```bash
   docker-compose -f srcs/docker-compose.yml build --no-cache nginx
```
3. Restart the service:
```bash
   docker-compose -f srcs/docker-compose.yml up -d nginx
```

### Modifying Configuration Files

**NGINX configuration:**
```bash
# Edit conf/nginx.conf
vim srcs/requirements/nginx/conf/nginx.conf

# Test configuration
docker exec nginx nginx -t

# Reload NGINX
docker exec nginx nginx -s reload

# Or rebuild container
docker-compose -f srcs/docker-compose.yml up -d --force-recreate nginx
```

**PHP-FPM configuration:**
```bash
# Edit conf/www.conf
vim srcs/requirements/wordpress/conf/www.conf

# Rebuild WordPress container
docker-compose -f srcs/docker-compose.yml build wordpress
docker-compose -f srcs/docker-compose.yml up -d wordpress
```

### Testing Changes
```bash
# Test NGINX can reach WordPress
docker exec nginx curl -I http://wordpress:9000

# Test WordPress can reach MariaDB
docker exec wordpress mysqladmin ping -h mariadb

# Test full stack
curl -k https://your_domain.42.fr
```

### Debugging

**Enable verbose logging:**

In Dockerfiles, add:
```dockerfile
RUN set -x
```

In shell scripts, add:
```bash
set -x  # Print commands as they execute
set -e  # Exit on error
```

**Check container resource usage:**
```bash
docker stats
```

**View recent container events:**
```bash
docker events --since 1h
```

**Examine failed container:**
```bash
# Get container ID
docker ps -a

# View logs
docker logs <container_id>

# Try to start interactively
docker start -ai <container_id>
```

## Advanced Topics

### Multi-stage Builds

While not currently used in this project, multi-stage builds can reduce image size:
```dockerfile
# Build stage
FROM debian:bullseye AS builder
RUN apt-get update && apt-get install -y build-essential
COPY source.c .
RUN gcc -o app source.c

# Final stage
FROM debian:bullseye-slim
COPY --from=builder /app /usr/local/bin/
CMD ["app"]
```

### Health Checks

Add health checks to docker-compose.yml:
```yaml
services:
  nginx:
    healthcheck:
      test: ["CMD", "curl", "-f", "https://localhost:443"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Resource Limits

Limit container resources:
```yaml
services:
  mariadb:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          memory: 256M
```

### Extending the Project

To add a new service:

1. Create directory: `srcs/requirements/newservice/`
2. Write Dockerfile
3. Add configuration files if needed
4. Write initialization script
5. Add to docker-compose.yml:
```yaml
   newservice:
     build: ./requirements/newservice
     container_name: newservice
     networks:
       - inception
     restart: always
```
6. Update Makefile if needed
7. Document in USER_DOC.md

## Troubleshooting

### Build Failures
```bash
# Clear build cache
docker builder prune

# Build with verbose output
docker-compose build --progress=plain --no-cache

# Check for syntax errors
docker-compose config
```

### Network Issues
```bash
# Recreate network
docker network rm inception
docker network create inception

# Check DNS
docker exec nginx cat /etc/resolv.conf
```

### Permission Issues
```bash
# Fix ownership
sudo chown -R $(whoami):$(whoami) ~/data

# Fix volume permissions
docker exec wordpress chown -R www-data:www-data /var/www/html
docker exec mariadb chown -R mysql:mysql /var/lib/mysql
```

### Port Conflicts
```bash
# Check what's using port 443
sudo lsof -i :443
sudo netstat -tulpn | grep 443

# Kill conflicting process
sudo kill <PID>
```

## Performance Optimization

### Image Size Optimization
```dockerfile
# Use specific versions
FROM debian:bullseye-slim

# Combine RUN commands
RUN apt-get update && \
    apt-get install -y package && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Don't install recommended packages
RUN apt-get install -y --no-install-recommends package
```

### Container Performance
```bash
# Monitor resource usage
docker stats --no-stream

# Check I/O
docker exec mariadb iostat -x 1 5

# Profile PHP-FPM
docker exec wordpress php-fpm7.4 -t
```

## Security Best Practices

**For development:**
- Keep secrets in `.env` file (git-ignored)
- Use self-signed certificates for HTTPS
- Run containers as non-root where possible

**For production:**
- Use Docker secrets for sensitive data
- Get real SSL certificates (Let's Encrypt)
- Enable Docker Content Trust
- Scan images for vulnerabilities
- Keep base images and packages updated
- Use read-only file systems where possible
- Enable AppArmor/SELinux
- Limit container capabilities

## Further Reading

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [Docker Security](https://docs.docker.com/engine/security/)