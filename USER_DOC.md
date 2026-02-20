# Inception - User Guide

Welcome! This guide will help you use and manage your WordPress website running on Docker.

## Quick Start

### Starting Your Website

To start everything, simply run:
```bash
make
```

Wait 1-2 minutes for the first startup. Your website will be available at:
```
https://your-login.42.fr
```

(Replace `your-login` with your actual username)

### Stopping Your Website

To stop all services:
```bash
make down
```

Don't worry - this keeps all your content and settings safe!

## Accessing Your Website

### View Your Website

Open your browser and go to:
```
https://your-login.42.fr
```

**You'll see a security warning** - this is normal! We use a self-signed certificate for development. Click "Advanced" → "Continue to site" to proceed.

### Admin Panel (Dashboard)

To manage your site, go to:
```
https://your-login.42.fr/wp-admin
```

Log in with your admin username and password (found in `srcs/secrets/.env` file).

**What you can do in the admin panel:**
- Write blog posts and create pages
- Upload photos and videos
- Change your site's look (themes)
- Add new features (plugins)
- Create new users
- Change site settings

## Your Login Information

All your passwords are stored in:
```
srcs/secrets/.env
```

**You have two users:**

1. **Administrator** (you) - Full control
   - Username: Check `WP_ADMIN_USER` in .env
   - Password: Check `WP_ADMIN_PASSWORD` in .env

2. **Author** (second user) - Can write and publish posts
   - Username: Check `WP_USER` in .env
   - Password: Check `WP_USER_PASSWORD` in .env

### Changing Your Password

**Option 1: Through WordPress Dashboard**
1. Log in to `/wp-admin`
2. Go to Users → Your Profile
3. Scroll down to "New Password"
4. Enter new password and save

**Option 2: Reset via command line**
```bash
docker exec wordpress wp user update YOUR_USERNAME --user_pass=NEW_PASSWORD --allow-root
```

## Basic Commands

### Check if Everything is Running
```bash
make status
```

This shows you:
- Which containers are running
- How long they've been up
- Your data storage locations

### View What's Happening (Logs)
```bash
make logs
```

Press `Ctrl+C` to stop viewing logs.

**See logs for just one service:**
```bash
make logs-nginx      # Web server
make logs-wordpress  # Your WordPress site
make logs-mariadb    # Database
```

### Restart Everything
```bash
make restart
```

## Troubleshooting

### Problem: Can't Access the Website

**Check 1:** Are the containers running?
```bash
docker ps
```

You should see three containers: `nginx`, `wordpress`, and `mariadb`.

**Check 2:** Is the domain configured?
```bash
grep your-login.42.fr /etc/hosts
```

If you don't see your domain, add it:
```bash
echo "127.0.0.1    your-login.42.fr" | sudo tee -a /etc/hosts
```

**Check 3:** Try restarting
```bash
make restart
```

### Problem: "502 Bad Gateway" Error

This means WordPress isn't responding. Fix it:
```bash
docker restart wordpress
make logs-wordpress
```

Wait a minute and refresh your browser.

### Problem: Forgot My Password

Reset it with this command:
```bash
docker exec wordpress wp user update YOUR_USERNAME --user_pass=NEW_PASSWORD --allow-root
```

Replace `YOUR_USERNAME` with your admin username and `NEW_PASSWORD` with what you want.

### Problem: Website is Slow

Check what's using resources:
```bash
docker stats
```

Press `Ctrl+C` to exit.

## Backing Up Your Website

### Create a Backup
```bash
# Stop the website
make down

# Create backup folder with today's date
mkdir -p ~/inception-backup-$(date +%Y%m%d)

# Copy everything important
cp -r ~/data ~/inception-backup-$(date +%Y%m%d)/
cp srcs/secrets/.env ~/inception-backup-$(date +%Y%m%d)/

# Start the website again
make up
```

Your backup is now in `~/inception-backup-YYYYMMDD/`

### Restore from Backup
```bash
# Stop the website
make down

# Restore your files (replace YYYYMMDD with your backup date)
cp -r ~/inception-backup-YYYYMMDD/data/* ~/data/
cp ~/inception-backup-YYYYMMDD/.env srcs/secrets/.env

# Start the website
make up
```

## Understanding Your Setup

Your WordPress website runs in three separate containers:

**NGINX** - The front door
- Handles visitors coming to your site
- Provides HTTPS security (the lock icon in browser)
- Sends page requests to WordPress

**WordPress** - Your website
- Creates your web pages
- Manages your content
- Runs the admin dashboard

**MariaDB** - Your database
- Stores all your posts, comments, and settings
- Like a filing cabinet for your website

**All your data is saved here:**
- `~/data/wordpress/` - Your website files and uploaded images
- `~/data/mariadb/` - Your database files

Even if you stop the containers, your data stays safe!

## Useful Tips

### Quick Health Check

Test if your site is responding:
```bash
curl -k -I https://your-login.42.fr
```

You should see `HTTP/1.1 200 OK` or similar.

### See WordPress Version
```bash
docker exec wordpress wp core version --allow-root
```

### Check Database Connection
```bash
docker exec mariadb mysqladmin ping -h localhost --silent && echo "Database OK"
```

## When You're Done

### Keep Everything (Recommended)
```bash
make down
```

Your website stops, but all your content is saved.

### Delete Everything (Clean Slate)
```bash
make fclean
```

**Warning:** This deletes ALL your content, posts, and settings! Only use this if you want to start completely fresh.

### Start Fresh After fclean
```bash
make all
```

## Security Reminders

🔒 **Important for your school project:**
- Your admin username CANNOT contain: `admin`, `Admin`, `administrator`, or `Administrator`
- Use strong, unique passwords
- Never share your `.env` file (it contains all your passwords!)
- The `.env` file should never be uploaded to Git

## Need Help?

**First steps:**
1. Check the logs: `make logs`
2. Look at the status: `make status`
3. Try restarting: `make restart`

**Still stuck?**
- Check your error messages carefully
- Look at the logs for specific services
- Make sure all containers are running with `docker ps`

**Resources:**
- WordPress Help: https://wordpress.org/support/
- Docker Docs: https://docs.docker.com/

---

**Remember:** Your data is persistent! Even if you stop containers or restart your computer, your WordPress content is safely stored in `~/data/`.