FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/ssl/private && \
    chmod 700 /etc/ssl/private

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/certs.sh /usr/local/bin/certs.sh
COPY tools/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/certs.sh /usr/local/bin/start.sh

EXPOSE 443

CMD ["start.sh"]