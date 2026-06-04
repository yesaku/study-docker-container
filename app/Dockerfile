FROM php:8.4-fpm-alpine

RUN apk add --no-cache netcat-openbsd \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && docker-php-ext-install pdo pdo_mysql \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

WORKDIR /var/www/html
COPY src/ .

EXPOSE 9000
