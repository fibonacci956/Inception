FROM alpine:3.23.5

RUN apk update && apk add --no-cache nginx openssl gettext

ARG DOMAIN_NAME
ENV DOMAIN_NAME=${DOMAIN_NAME}

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
