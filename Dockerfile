FROM alpine:3.24

LABEL maintainer="jolle@julian-paul.de"

RUN apk add --no-cache curl \
    zip \
    unzip \
    imagemagick \
    apache2 \
    php84 \
    php84-apache2 \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-ftp \
    php84-gd \
    php84-iconv \
    php84-mbstring \
    php84-mysqli \
    php84-opcache \
    php84-openssl \
    php84-pgsql \
    php84-sqlite3 \
    php84-tokenizer \
    php84-xml \
    php84-zip \
    su-exec
    
# Installing bash
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

### phpBB
ENV PHPBB_VERSION 3.3.19
ENV PHPBB_SHA256 '1530e5cabf7ecc9ecfaed3fa13da79f9e8a514623beafababc8800b5ce966de9'
# downloads.phpbb.de is offline: English package + German translation from GitHub
ENV PHPBB_DE_SHA256 '33ce89d62880f33dcb0b318d6a325582578406bf2ced583072e49baf3a854bf0'

WORKDIR /tmp

RUN echo "Europe/Berlin" > /etc/timezone
RUN curl -SL https://download.phpbb.com/pub/release/3.3/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}.zip -o phpbb.zip \
    && echo "${PHPBB_SHA256}  phpbb.zip" | sha256sum -c - \
    && curl -SL https://github.com/phpbb-de/phpbb-translation/archive/refs/tags/release-${PHPBB_VERSION}.tar.gz -o de.tar.gz \
    && echo "${PHPBB_DE_SHA256}  de.tar.gz" | sha256sum -c - \
    && unzip phpbb.zip \
    && mkdir /phpbb \
    && mkdir /phpbb/sqlite \
    && mv phpBB3 /phpbb/www \
    && mkdir de \
    && tar -xzf de.tar.gz --strip-components=1 -C de \
    && cp -r de/language de/styles de/ext /phpbb/www/ \
    && rm -rf phpbb.zip de.tar.gz de

COPY phpbb/config.php /phpbb/www

### Server
RUN mkdir -p /run/apache2 /phpbb/opcache \
    && chown apache:apache /run/apache2 /phpbb/opcache

COPY apache2/httpd.conf /etc/apache2/
COPY apache2/conf.d/* /etc/apache2/conf.d/


COPY php/php.ini /etc/php84/
COPY php/php-cli.ini /etc/php84/
COPY php/conf.d/* /etc/php84/conf.d/

COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

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
