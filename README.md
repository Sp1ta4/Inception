*This project has been created as part of the 42 curriculum by ggevorgi.*

# Inception

## Description

### Overview

Inception is a system administration project focused on **containerization using Docker**. The goal is to build a complete web infrastructure where each service runs in its own isolated container, demonstrating modern DevOps practices and container orchestration.

The project implements a **three-tier web architecture**:
- **NGINX** - Web server handling HTTPS traffic and TLS encryption
- **WordPress with PHP-FPM** - Content management system for dynamic web pages
- **MariaDB** - Relational database for persistent data storage

All services run in **separate Docker containers**, communicate through a **private Docker network**, and store data using **Docker volumes** with custom locations. The infrastructure is fully automated, reproducible, and follows Docker best practices.

### Why Docker?

Docker was chosen for this project because it provides:

**Isolation** - Each service runs in its own container with its own filesystem, processes, and network namespace. This means NGINX can't accidentally access MariaDB's data files, and a crash in one container doesn't affect others.

**Reproducibility** - The entire infrastructure is defined in code (Dockerfiles and docker-compose.yml). Anyone can rebuild the exact same environment on any machine that runs Docker.

**Efficiency** - Containers share the host kernel, making them much lighter than virtual machines. We can run three services on a single machine with minimal overhead.

**Portability** - The same containers work on any Linux system, macOS, or Windows with Docker installed. No "it works on my machine" problems.

**Version Control** - Infrastructure configuration is stored as code in Git, allowing tracking of changes, rollbacks, and collaboration.

### Project Sources and Structure
```
Inception/
├── Makefile                          # Automation commands
├── srcs/
│   ├── docker-compose.yml            # Container orchestration
│   ├── secrets/
│   │   └── .env                      # Environment variables (gitignored)
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile            # NGINX image definition
│       │   ├── conf/
│       │   │   └── nginx.conf        # NGINX configuration
│       │   └── tools/
│       │       ├── certs.sh          # TLS certificate generation
│       │       └── start.sh          # Container entrypoint
│       ├── wordpress/
│       │   ├── Dockerfile            # WordPress image definition
│       │   └── tools/
│       │       └── wp_setup.sh       # WordPress installation script
│       └── mariadb/
│           ├── Dockerfile            # MariaDB image definition
│           └── tools/
│               └── init_db.sh        # Database initialization script
└── /home/ggevorgi/data/              # Persistent data (host machine)
    ├── wordpress/                    # WordPress files and uploads
    └── mariadb/                      # Database files
```

**Key components:**

- **Dockerfiles** - Define how each container image is built (base OS, packages, configuration)
- **docker-compose.yml** - Orchestrates all containers, networks, and volumes
- **Shell scripts** - Handle initialization tasks (database setup, WordPress installation, TLS certificates)
- **Configuration files** - Customize each service (NGINX reverse proxy, PHP-FPM settings, MariaDB bind address)
- **.env file** - Stores all configuration variables and credentials (never committed to Git)

### Design Choices and Comparisons

#### Virtual Machines vs Docker

**Virtual Machines:**
- Run a complete operating system with its own kernel
- Provide hardware-level isolation through a hypervisor (VirtualBox, VMware, etc.)
- Heavy resource usage: each VM needs its own OS (~GB of RAM, GB of disk)
- Boot time: 30+ seconds to several minutes
- Strong isolation: VMs are completely separate from each other
- Use cases: Running different operating systems, strong security isolation, legacy applications

**Docker Containers:**
- Share the host's Linux kernel
- Provide process-level isolation using namespaces and cgroups
- Lightweight: containers share OS resources (~MB of RAM, MB of disk)
- Boot time: < 1 second
- Weaker isolation: containers share the kernel (but still well isolated for most use cases)
- Use cases: Microservices, CI/CD, development environments, cloud deployments

**Why Docker for this project:**

We need to run **three services on one machine** efficiently. With VMs, we'd need:
- 3 full operating systems = ~3-6 GB RAM just for the OS
- 3 separate kernels = duplicated resources
- Minutes to start all services

With Docker:
- Shared kernel = ~500 MB total for all containers
- Single OS overhead
- All services start in seconds

Docker gives us **isolation without the overhead**, perfect for running multiple related services together.

#### Secrets vs Environment Variables

**Environment Variables:**
- Simple key-value pairs passed to containers
- Easy to use: `docker run -e PASSWORD=secret`
- Visible in `docker inspect`, process listings (`ps aux`), and logs
- Stored in plain text in docker-compose.yml or .env files
- Best for: Non-sensitive configuration (ports, timeouts, feature flags)

**Docker Secrets:**
- Encrypted at rest in Docker's internal database
- Encrypted in transit when sent to containers
- Mounted as files in `/run/secrets/` (in-memory filesystem)
- Never visible in `docker inspect` or logs
- Only work with Docker Swarm (not standalone docker-compose)
- Best for: Passwords, API keys, certificates, private keys

**What I chose and why:**

For this project, I use **environment variables from a .env file**:
```bash
MYSQL_ROOT_PASSWORD=strongpassword
WP_ADMIN_PASSWORD=adminpass
```

**Advantages:**
- Simple to implement (no Swarm required)
- Easy to understand for a school project
- Works with docker-compose
- File permissions protect the .env file (chmod 600)
- Gitignored so never exposed in version control

**Limitations:**
- Visible in container inspection
- Not encrypted at rest
- Less secure than Docker secrets

**For production:** I would migrate to Docker Secrets or external secret management (HashiCorp Vault, AWS Secrets Manager) to properly protect credentials.

#### Docker Network vs Host Network

**Docker Bridge Network (what I use):**
- Creates an isolated virtual network for containers
- Each container gets its own IP address
- Containers communicate using DNS names (`mariadb`, `wordpress`)
- Only exposed ports are accessible from host (port 443 for NGINX)
- Network isolation: containers are hidden from external access by default

**Host Network:**
- Container shares the host's network namespace
- No IP address isolation
- Container can bind to any host port
- Slightly better performance (no NAT overhead)
- Security risk: container has direct access to host network

**Why I chose Bridge Network:**
```yaml
networks:
  inception:
    driver: bridge
```

**Benefits:**
1. **Security**: MariaDB port 3306 is NOT accessible from outside - only WordPress container can reach it
2. **DNS resolution**: WordPress connects to database using `mariadb` hostname, not IP addresses
3. **Port flexibility**: Multiple projects can run simultaneously without port conflicts
4. **Clean separation**: Services are logically grouped and isolated

**Example:** With bridge network, I can run:
```bash
wordpress -> mariadb:3306  # Works! Same network
curl localhost:3306        # Blocked! Not exposed to host
```

With host network, any service on localhost could access the database directly - a security risk.

**Performance trade-off:** Bridge networking adds ~1-2% overhead for network operations, but the security and manageability benefits far outweigh this minimal cost.

#### Docker Volumes vs Bind Mounts

**Bind Mounts:**
- Directly mount a host directory into a container
- Simple syntax: `-v /host/path:/container/path`
- Host path must exist before mounting
- Permission issues common (container UID vs host UID)
- Not managed by Docker (`docker volume ls` doesn't show them)
- Use case: Development when you want to edit files directly

**Docker Volumes:**
- Managed entirely by Docker
- Created with `docker volume create`
- Stored in Docker-managed location (`/var/lib/docker/volumes/`)
- Appear in `docker volume ls` and `docker volume inspect`
- Better performance on macOS/Windows (no filesystem translation)
- Easier backup and migration
- Use case: Production data that Docker should manage

**What I implemented (hybrid approach):**

The project requirement says: **"no bind mounts"** but also requires data in `/home/login/data`. So I use **Docker volumes with custom storage locations**:
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ggevorgi/data/mariadb
```

**What this does:**
- Creates a proper Docker volume (appears in `docker volume ls`)
- Stores data at a specific host location (`/home/ggevorgi/data/mariadb`)
- Docker manages the volume lifecycle
- Satisfies both requirements: "no bind mounts" + "data in /home/login/data"

**Benefits of this approach:**

1. **Docker management**: `docker volume inspect mariadb_data` shows volume details
2. **Consistent location**: Data always in `/home/login/data` as required
3. **Survives container deletion**: Data persists even after `docker-compose down`
4. **Clean up**: `docker volume rm mariadb_data` removes the volume properly

**Alternative (pure bind mount - NOT used):**
```yaml
volumes:
  - /home/ggevorgi/data/mariadb:/var/lib/mysql
```
This would work but violates the "no bind mounts" requirement and doesn't integrate with Docker's volume management system.

### Learning Outcomes

Through this project, I learned:

**Docker fundamentals:**
- Writing efficient Dockerfiles with multi-stage builds
- Container networking and inter-service communication
- Volume management and data persistence
- Docker Compose for multi-container orchestration

**System administration:**
- TLS/SSL certificate generation with OpenSSL
- NGINX configuration as a reverse proxy
- PHP-FPM configuration and FastCGI protocol
- MariaDB setup, user management, and security

**DevOps practices:**
- Infrastructure as Code (IaC)
- Automation with Makefiles
- Environment-based configuration
- Service health checking and logging

**Security concepts:**
- TLS encryption (TLSv1.2, TLSv1.3)
- Principle of least privilege (separate users, limited permissions)
- Network isolation
- Secret management challenges

## Instructions

### Prerequisites

Before starting, make sure you have:
- Docker Engine version 20.10 or higher
- Docker Compose version 1.29 or higher (or `docker compose` V2)
- GNU Make
- At least 2GB of available RAM
- A Linux system (tested on Ubuntu 20.04/22.04)
- `sudo` access for Docker operations

Check your versions:
```bash
docker --version
docker compose version
make --version
```

### Setup

**1. Clone the repository:**
```bash
git clone <repository-url>
cd Inception
```

**2. Create and configure your .env file:**

Copy the example and edit it:
```bash
mkdir -p srcs/secrets
nano srcs/secrets/.env
```

**Required variables** (replace with your own values):
```bash
# Data storage location
DATA_PATH=/home/ggevorgi/data

# Your domain (replace ggevorgi with your username)
DOMAIN_NAME=ggevorgi.42.fr

# Database configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=secure_db_password_123
MYSQL_ROOT_PASSWORD=secure_root_password_456

# WordPress admin (CANNOT contain: admin, Admin, administrator, Administrator)
WP_ADMIN_USER=siteowner
WP_ADMIN_PASSWORD=secure_admin_password_789
WP_ADMIN_EMAIL=admin@example.com
WP_TITLE=My Inception Website

# Second WordPress user (author role)
WP_USER=john
WP_USER_EMAIL=john@example.com
WP_USER_PASSWORD=secure_user_password_012
```

**Important:**
- Use **strong passwords** (mix of letters, numbers, symbols)
- Admin username **must NOT** contain `admin` or `administrator`
- Never commit the `.env` file to Git (it's in `.gitignore`)

**3. Add domain to hosts file:**
```bash
echo "127.0.0.1    ggevorgi.42.fr" | sudo tee -a /etc/hosts
```

(Replace `ggevorgi` with your actual username)

**4. Build and start everything:**
```bash
make
```

This will:
- Create data directories (`/home/ggevorgi/data/wordpress` and `/home/ggevorgi/data/mariadb`)
- Create Docker volumes
- Build all three Docker images
- Start all containers
- Generate self-signed TLS certificate
- Install and configure WordPress automatically

**Wait 1-2 minutes** for the first startup (WordPress needs to download and install).

**5. Access your website:**

Open your browser and navigate to:
```
https://ggevorgi.42.fr
```

You'll see a **security warning** about an untrusted certificate. This is normal because we use a self-signed certificate for local development.

**To proceed:**
- **Chrome/Edge**: Click "Advanced" → "Proceed to ggevorgi.42.fr (unsafe)"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
- **Safari**: Click "Show Details" → "visit this website"

### Available Commands

The Makefile provides these commands:
```bash
make              # Setup and start everything (default)
make up           # Start containers (if already built)
make down         # Stop containers (keeps data)
make restart      # Restart all services
make stop         # Stop without removing
make start        # Start stopped containers

make logs         # View logs from all containers (Ctrl+C to exit)
make logs-nginx   # View NGINX logs only
make logs-wordpress  # View WordPress logs only
make logs-mariadb    # View MariaDB logs only

make status       # Show containers, volumes, and data directories
make test         # Test if services are responding

make clean        # Remove containers and prune Docker system
make fclean       # Complete cleanup (removes ALL data!)
make re           # Rebuild everything from scratch (fclean + all)
```

**Examples:**
```bash
# Start your site
make

# Check if everything is running
make status

# Watch what's happening
make logs

# Stop for the night (data is kept)
make down

# Start again tomorrow
make up

# Something broken? Start fresh
make re
```

### Common Issues

**Issue: Can't access https://ggevorgi.42.fr**

Check if containers are running:
```bash
docker ps
```

You should see three containers: `nginx`, `wordpress`, `mariadb`.

If not, check logs:
```bash
make logs
```

**Issue: 502 Bad Gateway**

This means NGINX can't connect to WordPress (PHP-FPM not running).

Fix:
```bash
# Check if PHP-FPM is listening
docker exec wordpress ss -tuln | grep 9000

# If nothing shows, restart WordPress
docker restart wordpress

# Check logs for errors
make logs-wordpress
```

**Issue: WordPress can't connect to database**

Verify MariaDB is running and listening:
```bash
# Check if MariaDB is listening
docker exec mariadb ss -tuln | grep 3306

# Test database connection
docker exec mariadb mysqladmin ping -h localhost --silent && echo "OK"

# Check MariaDB logs
make logs-mariadb
```

**Issue: Permission denied on /home/ggevorgi/data**

Fix directory ownership:
```bash
sudo chown -R $(whoami):$(whoami) ~/data
sudo chmod -R 755 ~/data
```

**Issue: Port 443 already in use**

Another service (Apache, other NGINX) is using port 443.

Find and stop it:
```bash
sudo lsof -i :443
sudo systemctl stop apache2  # or nginx, etc.
```

**Issue: "version is obsolete" warning**

This is just a warning. The `version:` field in docker-compose.yml is deprecated but still works. You can safely ignore it or remove the line.

## Project Architecture

### Overview Diagram
```
                    Internet
                       |
                   [Port 443]
                       |
                 +-----v-----+
                 |   NGINX   |  (TLS/HTTPS)
                 |  Web      |
                 |  Server   |
                 +-----+-----+
                       |
                  [Port 9000]
                  FastCGI
                       |
                 +-----v-------+      [Port 3306]
                 | WordPress   +----->  MariaDB
                 | + PHP-FPM   |       Database
                 +-------------+
                       |
                       v
              [wordpress_data]    [mariadb_data]
              /var/www/html       /var/lib/mysql
                       |                  |
                       v                  v
              ~/data/wordpress    ~/data/mariadb
```

### Service Details

#### NGINX Container

**Base image:** `debian:bullseye`

**Purpose:** Acts as a reverse proxy and TLS termination point.

**What it does:**
1. Listens on port 443 (HTTPS) for incoming connections
2. Uses a self-signed TLS certificate for encryption
3. Serves static files (CSS, images, JavaScript) directly
4. Forwards PHP requests to WordPress container via FastCGI
5. Only supports TLSv1.2 and TLSv1.3 (no older, insecure protocols)

**Key configuration:**
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;  # Forward to WordPress
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

**Volumes:** Mounts `wordpress_data` as read-only to serve static files

**Network:** Exposes port 443 to host, connects to WordPress on private network

#### WordPress Container

**Base image:** `debian:bullseye`

**Installed software:**
- PHP 7.4 with PHP-FPM
- PHP extensions: php7.4-mysql (database connection)
- WP-CLI (WordPress command-line tool)
- MariaDB client (for database checks)

**Purpose:** Runs the WordPress application and serves dynamic content.

**Initialization process** (`wp_setup.sh`):
1. Wait for MariaDB to be ready (`mysqladmin ping`)
2. Download WordPress core files (if not already installed)
3. Generate `wp-config.php` with database credentials
4. Install WordPress with site title and admin user
5. Create a second user with `author` role
6. Start PHP-FPM in foreground mode (keeps container running)

**Key configuration:**
- PHP-FPM listens on port 9000 (not Unix socket)
- Connects to database using hostname `mariadb` (Docker DNS)

**Volumes:** Mounts `wordpress_data` at `/var/www/html` for WordPress files and uploads

**Network:** Receives FastCGI requests from NGINX, connects to MariaDB database

#### MariaDB Container

**Base image:** `debian:bullseye`

**Installed software:**
- MariaDB Server (MySQL-compatible database)

**Purpose:** Stores all WordPress data (posts, users, settings, comments).

**Initialization process** (`init_db.sh`):
1. Start MariaDB service temporarily
2. Create WordPress database
3. Create WordPress user with privileges
4. Set root password
5. Flush privileges
6. Stop temporary service
7. Start MariaDB in foreground mode (production mode)

**Key configuration:**
```ini
bind-address = 0.0.0.0  # Listen on all interfaces (allows WordPress to connect)
```

**Security:**
- Root password required
- Dedicated user for WordPress (principle of least privilege)
- Only accessible within Docker network (not exposed to host)

**Volumes:** Mounts `mariadb_data` at `/var/lib/mysql` for database files

**Network:** Listens on port 3306, only accessible from WordPress container

### Networking

All containers are connected to a **bridge network** named `inception`:
```yaml
networks:
  inception:
    driver: bridge
```

**How services communicate:**
```
NGINX        → wordpress:9000   (FastCGI)
WordPress    → mariadb:3306     (MySQL protocol)
Host browser → localhost:443    (HTTPS) → NGINX
```

**DNS resolution:** Docker provides automatic DNS. Containers can reach each other using their service names as hostnames.

**Port exposure:**
- **443** (NGINX) → Exposed to host (accessible from browser)
- **9000** (WordPress) → Internal only
- **3306** (MariaDB) → Internal only

This means:
-  You can access the website at `https://localhost:443`
-  You cannot directly access `localhost:9000` (PHP-FPM)
-  You cannot directly access `localhost:3306` (database)

This is a security feature - only the web server is publicly accessible.

### Data Persistence

Data is stored in two Docker volumes:
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ggevorgi/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ggevorgi/data/mariadb
```

**What gets stored where:**

**wordpress_data** (`/var/www/html` in container):
- WordPress core files
- Themes and plugins
- Uploaded media (images, videos)
- User-created content files

**mariadb_data** (`/var/lib/mysql` in container):
- Database tables
- User data
- Post content
- Site configuration

**Why this matters:**

Even if you run `docker-compose down` and remove all containers, your data survives in `/home/ggevorgi/data/`. When you run `make up` again, WordPress and MariaDB reuse the existing data - your site is exactly as you left it.

**To completely start fresh:**
```bash
make fclean  # Removes containers AND data
make         # Rebuilds everything from scratch
```

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/) - Complete Docker reference
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/) - docker-compose.yml syntax
- [NGINX Documentation](https://nginx.org/en/docs/) - NGINX configuration guide
- [WordPress Developer Resources](https://developer.wordpress.org/) - WordPress APIs and hooks
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) - MariaDB server documentation
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/) - WordPress command-line tool

### Tutorials and Learning Resources

- [Docker Curriculum](https://docker-curriculum.com/) - Beginner-friendly Docker tutorial
- [Understanding Docker Volumes](https://docs.docker.com/storage/volumes/) - Data persistence in Docker
- [NGINX as Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/) - Proxying requests
- [WordPress with Docker (Video)](https://www.youtube.com/watch?v=mKdwkV5p1xg) - Visual walkthrough
- [OpenSSL Certificate Generation](https://www.openssl.org/docs/man1.1.1/man1/req.html) - Creating TLS certificates
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php) - PHP FastCGI Process Manager

### Useful Docker Commands
```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs <container_name>
docker logs -f <container_name>  # Follow logs in real-time

# Execute command in running container
docker exec <container_name> <command>
docker exec -it <container_name> bash  # Interactive shell

# Inspect container details
docker inspect <container_name>

# View resource usage
docker stats

# List volumes
docker volume ls

# Inspect volume details
docker volume inspect <volume_name>

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything (use carefully!)
docker system prune -a --volumes
```

### AI Usage Transparency

AI (Claude by Anthropic) was used as a learning assistant throughout this project:

**Learning and understanding:**
- Explaining Docker concepts (namespaces, cgroups, overlay filesystems)
- Clarifying differences between approaches (volumes vs bind mounts, bridge vs host networking)
- Understanding security implications of design choices
- Learning Dockerfile best practices (layer caching, multi-stage builds)

**Debugging and troubleshooting:**
- Interpreting error messages and container logs
- Identifying configuration issues (PHP-FPM socket vs port, MariaDB bind-address)
- Solving permission problems with volumes
- Debugging network connectivity between containers

**Configuration and scripting:**
- NGINX reverse proxy configuration examples
- Docker Compose syntax and volume definitions
- Shell script development (init_db.sh, wp_setup.sh, certs.sh)
- Makefile structure and target dependencies

**Documentation:**
- Structuring this README
- Explaining technical concepts clearly
- Providing examples and troubleshooting guides

**What AI didn't do:**
- Make architectural decisions (I chose the bridge network, volume approach, service structure)
- Understand the project requirements (I read and interpreted the subject)
- Test the implementation (I ran all commands, fixed issues, and verified functionality)
- Write the code without my understanding (every line was reviewed, tested, and often modified)

**AI served as:**
- A patient teacher explaining complex concepts
- A reference manual with interactive clarification
- A rubber duck for debugging (explaining problems often revealed solutions)
- A code reviewer suggesting improvements

This is similar to using Stack Overflow, technical documentation, or asking a senior developer for guidance - but with the advantage of interactive, personalized explanations.

The final implementation, understanding, and responsibility for the project are entirely mine.

---

**Date:** February 2026