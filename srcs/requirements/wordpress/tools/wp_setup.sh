#!/bin/bash

if [ -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress already installed"
    exec php-fpm7.4 -F
fi

echo "Waiting for MariaDB..."

until mysqladmin ping -h mariadb --silent; do
    sleep 1
done

echo "MariaDB is ready"

wp core download --allow-root

wp config create \
    --dbname=$MYSQL_DATABASE \
    --dbuser=$MYSQL_USER \
    --dbpass=$MYSQL_PASSWORD \
    --dbhost=mariadb \
    --allow-root

wp core install \
    --url=https://$DOMAIN_NAME \
    --title="$WP_TITLE" \
    --admin_user=$WP_ADMIN_USER \
    --admin_password=$WP_ADMIN_PASSWORD \
    --admin_email=$WP_ADMIN_EMAIL \
    --skip-email \
    --allow-root

wp user create \
    $WP_USER $WP_USER_EMAIL \
    --role=author \
    --user_pass=$WP_USER_PASSWORD \
    --allow-root

echo "WordPress installed successfully"

exec php-fpm7.4 -F