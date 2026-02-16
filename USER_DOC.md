# User Documentation

This document provides instructions for end users and administrators on how to use and manage the Inception infrastructure.

## What Services Are Provided

The infrastructure consists of three main services working together to provide a complete WordPress website:

**NGINX Web Server**
- Serves your website over HTTPS (secure connection)
- Handles all incoming web traffic on port 443
- Provides TLS encryption for security
- Acts as a reverse proxy, forwarding PHP requests to WordPress

**WordPress Content Management System**
- Allows you to create and manage website content
- Provides an admin panel for site management
- Runs with PHP-FPM for processing dynamic content
- Stores posts, pages, media, and site settings

**MariaDB Database**
- Stores all WordPress data (posts, users, settings, etc.)
- Handles all database operations
- Ensures data persistence and integrity

All services run in isolated Docker containers and communicate through a private network. Your data is stored persistently on the host machine, so it survives container restarts.

## Starting and Stopping the Project

### Starting the Infrastructure

To start all services, run:
```bash
make
```

This command will:
- Create necessary data directories
- Build Docker images if needed
- Start all three containers
- Generate TLS certificates if they don't exist
- Install and configure WordPress automatically

The first start takes longer (1-2 minutes) because it downloads base images and installs WordPress. Subsequent starts are much faster.

### Stopping the Infrastructure

To stop all services while keeping your data:
```bash
make down
```

This stops the containers but preserves all your data, settings, and content.

### Restarting Services

If you need to restart the services:
```bash
make restart
```

Or restart individual services:
```bash
docker restart nginx
docker restart wordpress
docker restart mariadb
```

## Accessing the Website

### Accessing the Public Site

Open your web browser and navigate to:
```
https://codeex.42.fr
```

Replace `codeex` with your actual username.

**Note about the security warning:** You will see a warning about an untrusted certificate. This is normal because we use a self-signed certificate for local development. Click "Advanced" or "Continue to site" to proceed.

### Accessing the Administration Panel

To manage your WordPress site, go to:
```
https://codeex.42.fr/wp-admin
```

Log in with your administrator credentials (see Credentials section below).

From the admin panel you can:
- Create and edit posts and pages
- Upload media (images, videos, documents)
- Install themes and plugins
- Manage users
- Configure site settings
- View site statistics

## Managing Credentials

### Location of Credentials

All credentials are stored in the environment file:
```
srcs/secrets/.env
```

**Important:** This file should never be committed to version control. It's included in `.gitignore` to prevent accidental exposure.

### Available Credentials

**WordPress Administrator**
- Username: Value of `WP_ADMIN_USER`
- Password: Value of `WP_ADMIN_PASSWORD`
- Email: Value of `WP_ADMIN_EMAIL`
- Purpose: Full access to WordPress admin panel

**WordPress Editor**
- Username: Value of `WP_USER`
- Password: Value of `WP_USER_PASSWORD`
- Email: Value of `WP_USER_EMAIL`
- Purpose: Can create and edit posts but has limited admin access

**Database Root User**
- Username: `root`
- Password: Value of `MYSQL_ROOT_PASSWORD`
- Purpose: Full database administration (rarely needed)

**Database WordPress User**
- Username: Value of `MYSQL_USER`
- Password: Value of `MYSQL_PASSWORD`
- Purpose: WordPress uses this to connect to the database

### Changing Credentials

To change any credentials:

1. Stop the services:
```bash
   make down
```

2. Edit `srcs/secrets/.env` with your new credentials

3. For database credentials, you'll need to rebuild:
```bash
   make fclean
   make
```

4. For WordPress user credentials, you can change them through the admin panel or rebuild

**Warning:** Changing database credentials on a running system requires careful migration. It's easier to do this before first deployment.

## Checking Service Health

### Quick Status Check

View the status of all containers and volumes:
```bash
make status
```

This shows:
- Running containers and their uptime
- Available volumes
- Data directory contents

### Viewing Service Logs

To see what's happening in real-time:
```bash
make logs
```

To view logs for a specific service:
```bash
make logs-nginx
make logs-wordpress
make logs-mariadb
```

To exit the logs view, press `Ctrl+C`.

### Checking Individual Services

**Check if NGINX is responding:**
```bash
curl -k -I https://codeex.42.fr
```

You should see `HTTP/1.1 200 OK` or `HTTP/1.1 302 Found`.

**Check if MariaDB is running:**
```bash
docker exec mariadb mysqladmin ping -h localhost --silent && echo "MariaDB OK"
```

**Check if WordPress is installed:**
```bash
docker exec wordpress wp core version --allow-root
```

This shows the WordPress version number.

**Check if containers are running:**
```bash
docker ps
```

You should see three containers with status "Up".

### Verifying Data Persistence

Your data is stored in:
```
/home/codeex/data/wordpress/  - WordPress files and uploads
/home/codeex/data/mariadb/    - Database files
```

To check if data exists:
```bash
ls -lh ~/data/wordpress/
ls -lh ~/data/mariadb/
```

## Common Issues and Solutions

### Issue: Cannot access the website

**Solution:**

1. Check if all containers are running:
```bash
   docker ps
```

2. Check if the domain is in your hosts file:
```bash
   grep codeex.42.fr /etc/hosts
```
   
   If not present, add it:
```bash
   echo "127.0.0.1    codeex.42.fr" | sudo tee -a /etc/hosts
```

3. Check NGINX logs:
```bash
   make logs-nginx
```

### Issue: 502 Bad Gateway

This means NGINX cannot connect to WordPress.

**Solution:**
```bash
# Check if WordPress is running
docker ps | grep wordpress

# Restart WordPress
docker restart wordpress

# Check logs
make logs-wordpress
```

### Issue: Forgot admin password

**Solution:**

You can reset it using WP-CLI:
```bash
docker exec wordpress wp user update admin_username --user_pass=new_password --allow-root
```

Replace `admin_username` with your actual admin username.

### Issue: Website is slow

**Solution:**

1. Check container resource usage:
```bash
   docker stats
```

2. Check if database needs optimization:
```bash
   docker exec mariadb mysqlcheck -u root -p --optimize --all-databases
```
   
   Enter the root password when prompted.

## Backup and Restore

### Creating a Backup

To backup your entire site:
```bash
# Stop containers
make down

# Create backup directory
mkdir -p ~/inception-backup-$(date +%Y%m%d)

# Copy data
cp -r ~/data ~/inception-backup-$(date +%Y%m%d)/
cp srcs/secrets/.env ~/inception-backup-$(date +%Y%m%d)/

# Restart containers
make up
```

### Restoring from Backup
```bash
# Stop containers
make down

# Restore data
cp -r ~/inception-backup-YYYYMMDD/data/* ~/data/
cp ~/inception-backup-YYYYMMDD/.env srcs/secrets/.env

# Start containers
make up
```

## Security Recommendations

**For Production Use:**

1. Replace the self-signed certificate with a real SSL certificate (Let's Encrypt)
2. Use strong, unique passwords for all accounts
3. Keep WordPress, themes, and plugins updated
4. Regularly backup your data
5. Monitor logs for suspicious activity
6. Consider using Docker secrets instead of environment variables
7. Limit WordPress admin panel access to specific IP addresses
8. Enable WordPress security plugins
9. Use a firewall to restrict access to ports other than 443

## Getting Help

If you encounter issues:

1. Check the logs: `make logs`
2. Verify services are running: `make status`
3. Review the error messages carefully
4. Consult the developer documentation (DEV_DOC.md) for technical details
5. Check Docker documentation: https://docs.docker.com/
6. Check WordPress support: https://wordpress.org/support/