FROM alpine:3.23.5

RUN apk add --no-cache mariadb mariadb-client \
    && sed -i '/^skip-networking/d' /etc/my.cnf.d/mariadb-server.cnf

COPY conf/my.cnf /etc/my.cnf.d/my.cnf
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/entrypoint.sh"]
