FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y \
        php7.4 \
        php7.4-fpm \
        php7.4-mysql \
        curl \
        mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY tools/wp_setup.sh /usr/local/bin/wp_setup.sh
RUN chmod +x /usr/local/bin/wp_setup.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["wp_setup.sh"]
