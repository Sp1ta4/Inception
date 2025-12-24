FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/ssl/private

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/certs.sh /usr/local/bin/certs.sh

RUN chmod +x /usr/local/bin/certs.sh

EXPOSE 443

CMD ["sh", "-c", "certs.sh && nginx -g 'daemon off;'"]
