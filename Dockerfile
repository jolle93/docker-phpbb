FROM alpine:3.14

LABEL maintainer="jolle@julian-paul.de"

RUN apk add --no-cache curl \
    zip \
    unzip \
    imagemagick \
    apache2 \
    php8 \
    php8-apache2 \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-ftp \
    php8-gd \
    php8-iconv \
    php8-json \
    php8-mbstring \
    php8-mysqli \
    php8-opcache \
    php8-openssl \
    php8-pgsql \
    php8-sqlite3 \
    php8-tokenizer \
    php8-xml \
    php8-zlib \
    php8-zip \
    su-exec
    
# Installing bash
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

### phpBB
ENV PHPBB_VERSION 3.3.5
ENV PHPBB_SHA256 'b72962629d3166e6344c362c5f6deee5ee5aae13750dec85efa4c80288211907'

WORKDIR /tmp

RUN echo "Europe/Berlin" > /etc/timezone
RUN curl -SL https://downloads.phpbb.de/pakete/deutsch/3.3/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}-deutsch.zip -o phpbb.zip \
    && echo "${PHPBB_SHA256}  phpbb.zip" | sha256sum -c - \
    && unzip phpbb.zip \
    && mkdir /phpbb \
    && mkdir /phpbb/sqlite \
    && mv phpBB3 /phpbb/www \
    && rm -f phpbb.zip

COPY phpbb/config.php /phpbb/www

### Server
RUN mkdir -p /run/apache2 /phpbb/opcache \
    && chown apache:apache /run/apache2 /phpbb/opcache

COPY apache2/httpd.conf /etc/apache2/
COPY apache2/conf.d/* /etc/apache2/conf.d/

COPY remoteip.conf /etc/apache2/conf.d

COPY php/php.ini /etc/php8/
COPY php/php-cli.ini /etc/php8/
COPY php/conf.d/* /etc/php8/conf.d/

COPY start.sh /usr/local/bin/

RUN chown -R apache:apache /phpbb
WORKDIR /phpbb/www

#VOLUME /phpbb/sqlite
#VOLUME /phpbb/www/files
#VOLUME /phpbb/www/store
#VOLUME /phpbb/www/images/avatars/upload

ENV PHPBB_INSTALL= \
    PHPBB_DB_DRIVER=sqlite3 \
    PHPBB_DB_HOST=/phpbb/sqlite/sqlite.db \
    PHPBB_DB_PORT= \
    PHPBB_DB_NAME= \
    PHPBB_DB_USER= \
    PHPBB_DB_PASSWD= \
    PHPBB_DB_TABLE_PREFIX=phpbb_ \
    PHPBB_DB_AUTOMIGRATE= \
    PHPBB_DISPLAY_LOAD_TIME= \
    PHPBB_DEBUG= \
    PHPBB_DEBUG_CONTAINER=

EXPOSE 80
CMD ["start.sh"]
