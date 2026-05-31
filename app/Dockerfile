FROM php:8.4-fpm-alpine

RUN apk add --no-cache netcat-openbsd \
    && docker-php-ext-install pdo pdo_mysql \
    && pecl install redis \
    && docker-php-ext-enable redis

WORKDIR /var/www/html
COPY src/ .

EXPOSE 9000
