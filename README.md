*This project has been created as part of the 42 curriculum by ggevorgi.*

# Inception

## Description

Inception is a system administration project that focuses on containerization using Docker. The main goal is to set up a complete web infrastructure with multiple services, each running in its own container.

The project consists of three main services:
- NGINX web server with TLS encryption
- WordPress with PHP-FPM for content management
- MariaDB database for data storage

All services are isolated in separate Docker containers, communicate through a private network, and store their data persistently using Docker volumes. The infrastructure is designed to be reproducible, secure, and follows modern containerization practices.

Through this project, I learned about Docker image creation, container orchestration with Docker Compose, inter-container networking, data persistence, and basic system administration concepts like TLS certificate generation and service configuration.

## Instructions

### Prerequisites

Before starting, make sure you have:
- Docker Engine version 20.10 or higher
- Docker Compose version 1.29 or higher
- GNU Make
- At least 2GB of available RAM
- A Linux system (tested on Ubuntu 20.04)

### Setup

First, clone the repository and navigate to the project directory:
```bash
git clone <repository-url>
cd Inception
```

Next, configure your environment variables. Edit the file `srcs/secrets/.env` with your settings. Replace `ggevorgi` with your own username:
```bash
DATA_PATH=/home/ggevorgi/data
DOMAIN_NAME=ggevorgi.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_root_password

WP_ADMIN_USER=siteowner
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=admin@example.com

WP_USER=editor
WP_USER_EMAIL=editor@example.com
WP_USER_PASSWORD=editor_password
```

Add your domain to the hosts file so it resolves to localhost:
```bash
echo "127.0.0.1    ggevorgi.42.fr" | sudo tee -a /etc/hosts
```

Now you can build and start the infrastructure:
```bash
make
```

This command will create the necessary directories, build all Docker images, start the containers, generate TLS certificates, and install WordPress automatically.

Once everything is running, open your browser and go to `https://ggevorgi.42.fr`. You'll see a security warning because we're using a self-signed certificate - this is normal for local development. Click through the warning to access your WordPress site.

### Available Commands

The Makefile provides several useful commands:

- `make` - Set up directories and start all containers
- `make up` - Start the containers
- `make down` - Stop all containers
- `make restart` - Restart all services
- `make logs` - View logs from all containers
- `make status` - Show information about containers, volumes, and data directories
- `make clean` - Remove containers and clean up Docker resources
- `make fclean` - Complete cleanup including all data
- `make re` - Rebuild everything from scratch

### Common Issues

If you see a 502 Bad Gateway error, check that PHP-FPM is running correctly:
```bash
docker exec wordpress ss -tuln | grep 9000
make logs-wordpress
```

If WordPress can't connect to MariaDB, verify the database is listening on the correct address:
```bash
docker exec mariadb ss -tuln | grep 3306
make logs-mariadb
```

If you encounter permission errors with the data directories, fix ownership with:
```bash
sudo chown -R $(whoami):$(whoami) ~/data
```

## Project Architecture

The infrastructure consists of three containers connected through a private Docker network. NGINX listens on port 443 (HTTPS) and acts as the entry point, forwarding PHP requests to WordPress via FastCGI on port 9000. WordPress connects to MariaDB on port 3306 for database operations.

Data persistence is handled by two Docker volumes that store their data in `/home/ggevorgi/data/wordpress` and `/home/ggevorgi/data/mariadb` on the host machine.

### NGINX Container

Built from Debian Bullseye, this container runs NGINX as a reverse proxy and web server. It handles TLS encryption using a self-signed certificate generated at startup, supporting only TLSv1.2 and TLSv1.3 protocols. The server forwards PHP requests to the WordPress container using FastCGI and serves static files directly.

### WordPress Container

Also based on Debian Bullseye, this container runs PHP-FPM 7.4 and includes WP-CLI for WordPress management. During initialization, it waits for MariaDB to be ready, downloads WordPress core files, creates the configuration, installs WordPress, and sets up two users (an administrator and an editor). PHP-FPM listens on port 9000 for incoming requests from NGINX.

### MariaDB Container

The database container runs MariaDB on Debian Bullseye. On first start, it initializes the database system, creates the WordPress database, sets up user privileges, and configures the root password. The server is configured to listen on all network interfaces (0.0.0.0:3306) so WordPress can connect from its container.

## Technical Choices

### Virtual Machines vs Docker

Virtual machines provide hardware-level isolation through a hypervisor, meaning each VM runs a complete operating system. This makes them resource-intensive, with boot times measured in minutes and image sizes in gigabytes. VMs offer strong isolation but at the cost of performance overhead.

Docker containers, on the other hand, use process-level isolation through Linux kernel namespaces and cgroups. They share the host's kernel, making them much more lightweight. Containers start in seconds, use significantly less memory and disk space, and have near-native performance. For this project, Docker was the obvious choice because we need to run multiple services on a single machine efficiently, and we benefit from faster development iteration and easier deployment.

### Secrets vs Environment Variables

Environment variables are convenient for configuration but not ideal for sensitive data. They're visible in container inspection, process listings, and logs. In this project, I use environment variables from a `.env` file for both configuration and credentials. This works for a development/school environment where the `.env` file is properly protected by filesystem permissions and git-ignored.

Docker secrets provide better security by encrypting sensitive data at rest and in transit, storing it in Docker's encrypted store, and mounting it as files in containers at runtime. For a production deployment, I would migrate all passwords and sensitive data to Docker secrets. The current approach with environment variables is acceptable for this educational context but represents a known limitation.

### Docker Network vs Host Network

Docker's bridge network driver creates an isolated network namespace for containers. Containers can communicate with each other using DNS names (like `mariadb` or `wordpress`) without knowing each other's IP addresses. Only explicitly exposed ports (like port 443 for NGINX) are accessible from the host. This provides good security and flexibility.

Host network mode removes this isolation entirely. Containers share the host's network stack, which means better performance but also security risks, potential port conflicts, and loss of the convenient container-to-container DNS resolution. For this project, bridge networking makes sense because the slight performance overhead is negligible, and the isolation and ease of configuration are more valuable.

### Docker Volumes vs Bind Mounts

Bind mounts directly map a host directory to a container path. They're simple but have drawbacks: they bypass Docker's management system, don't appear in `docker volume ls`, and can have permission issues. The project requirements explicitly forbid bind mounts.

Instead, I use named Docker volumes with custom storage locations. This is implemented using the local driver with specific driver options:
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ggevorgi/data/wordpress
```

This approach gives us the best of both worlds. Docker manages the volumes (they appear in `docker volume ls` and `docker volume inspect`), but the data physically resides in a specified location on the host (`/home/ggevorgi/data/`). This satisfies the requirement to store data in `/home/login/data` while maintaining proper volume management through Docker.

## Resources

### Documentation

- Docker Documentation: https://docs.docker.com/
- Docker Compose Reference: https://docs.docker.com/compose/compose-file/
- NGINX Documentation: https://nginx.org/en/docs/
- WordPress Developer Resources: https://developer.wordpress.org/
- MariaDB Knowledge Base: https://mariadb.com/kb/en/

### Tutorials and Articles

- Docker for Beginners by Docker: https://docker-curriculum.com/
- Understanding Docker Volumes: https://docs.docker.com/storage/volumes/
- NGINX Reverse Proxy Configuration: https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/
- WordPress with Docker: https://docs.docker.com/samples/wordpress/
- WordPress with Docker: https://www.youtube.com/watch?v=mKdwkV5p1xg
- TLS/SSL Certificate Generation with OpenSSL

### AI Usage

AI (Claude by Anthropic) was used as a learning assistant throughout this project for the following purposes:

**Understanding concepts**: I used AI to explain Docker concepts like volumes, networks, and multi-stage builds. It helped me understand the differences between various approaches and why certain design patterns are considered best practices.

**Debugging assistance**: When encountering errors, I would paste error messages and relevant configuration to get explanations of what went wrong and suggestions for fixes. This was particularly helpful for issues like PHP-FPM not listening on the correct port or MariaDB bind-address configuration problems.

**Configuration examples**: AI provided example configurations for NGINX FastCGI proxy setup, Docker Compose volume definitions, and Dockerfile best practices. I would then adapt these examples to my specific needs rather than copying them directly.

**Script development**: The shell scripts for initializing MariaDB and WordPress were developed with AI assistance. I would describe what I needed to accomplish, receive a script suggestion, test it, and then iterate with AI to handle edge cases and improve error handling.

**Makefile creation**: AI helped structure the Makefile with proper targets and dependencies, though I made modifications based on my specific workflow needs.

The core architecture decisions, understanding of how the services interact, and the overall implementation approach were my own. AI served as a teaching tool and reference, similar to how one might use Stack Overflow or technical documentation, but with the advantage of interactive dialogue for clarification.