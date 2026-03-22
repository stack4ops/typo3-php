FROM docker.io/library/php:8.4-fpm

LABEL maintainer="Stefan Schneider <eqsoft4@gmail.com>"

ARG TARGETARCH

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG ALL_PROXY
ARG http_proxy=$HTTP_PROXY
ARG https_proxy=$HTTPS_PROXY
ARG no_proxy=$NO_PROXY
ARG all_proxy=$ALL_PROXY

USER root

ENV TZ=Europe/Berlin

ARG UID=33
ARG GID=33

COPY ./files/docker-php-entrypoint /usr/local/bin/

WORKDIR /var/www/html/public

RUN <<EOF
set -eux
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
git \
ghostscript \
graphicsmagick \
libfreetype6-dev \
libicu-dev \
libjpeg62-turbo-dev \
libkrb5-dev \
libpng-dev \
libzip-dev \
locales \
locales-all \
openssh-client \
unzip \
zip
docker-php-ext-configure gd --with-freetype --with-jpeg
docker-php-ext-configure intl
docker-php-ext-configure opcache --enable-opcache
docker-php-ext-install -j$(nproc) \
exif \
gd \
intl \
mysqli \
opcache \
pdo_mysql \
zip
pecl install \
apcu \
redis
docker-php-ext-enable \
apcu \
redis
EOF

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

COPY ./files/etc/conf.d /usr/local/etc/php/conf.d

# copy ca certs
COPY ./files/crt/ /usr/share/ca-certificates/
COPY ./files/crt/ /usr/local/share/ca-certificates/
RUN <<EOF
set -e
echo root-ca.crt >> /etc/ca-certificates.conf
echo signing-ca.crt >> /etc/ca-certificates.conf
update-ca-certificates
EOF

RUN chown -R "$UID:$GID" /var/www/html
USER "$UID:$GID"
