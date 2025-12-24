#!/bin/bash

if [ -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "MariaDB already initialized"
    exec mysqld_safe
fi

echo "Initializing MariaDB..."

mysqld_safe &

until mysqladmin ping --silent; do
    sleep 1
done

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

echo "MariaDB initialized"

exec mysqld_safe
