FROM alpine:3.23.5

ARG WP_CLI_VERSION
ARG WP_CLI_SHA512

# PHP extensions required/recommended by WordPress core:
# https://make.wordpress.org/hosting/handbook/server-environment/#php-extensions
RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-gd \
    php83-curl \
    php83-mbstring \
    php83-xml \
    php83-zip \
    php83-opcache \
    php83-session \
    php83-json \
    php83-phar \
    php83-openssl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-intl \
    mariadb-client \
    curl

RUN ln -s /usr/bin/php83 /usr/local/bin/php \
    && curl -fsSL -o /usr/local/bin/wp \
       "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
    && echo "${WP_CLI_SHA512}  /usr/local/bin/wp" | sha512sum -c - \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN addgroup -g 1000 -S wordpress \
    && adduser -u 1000 -D -S -G wordpress wordpress

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
