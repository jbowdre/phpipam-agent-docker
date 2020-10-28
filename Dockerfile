FROM php:5.6-apache

ARG TARGETPLATFORM
RUN echo "TARGETPLATFORM : $TARGETPLATFORM"

ENV PHPIPAM_AGENT_SOURCE https://github.com/phpipam/phpipam-agent

# Install required deb packages
RUN sed -i /etc/apt/sources.list -e 's/$/ non-free'/ && \
    apt-get update && apt-get -y upgrade && \
    rm /etc/apt/preferences.d/no-debian-php && \
    apt-get install -y git cron libgmp-dev iputils-ping fping && \
    rm -rf /var/lib/apt/lists/*

# Configure apache and required PHP modules
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install json && \
    docker-php-ext-install pdo_mysql && \
    \
    if [ "$TARGETPLATFORM" = "linux/386" ] ; then XARCH="i386-linux-gnu" ; fi && \
    if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then XARCH="x86_64-linux-gnu" ; fi && \
    if [ "$TARGETPLATFORM" = "linux/arm/v6" ] ; then XARCH="arm-linux-gnueabi" ; fi && \
    if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then XARCH="arm-linux-gnueabihf" ; fi && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then XARCH="aarch64-linux-gnu" ; fi && \
    \
    ln -s /usr/include/$XARCH/gmp.h /usr/include/gmp.h && \
    docker-php-ext-configure gmp --with-gmp=/usr/include/$XARCH && \
    docker-php-ext-install gmp && \
    docker-php-ext-install pcntl

COPY php.ini /usr/local/etc/php/

# Clone phpipam-agent sources
WORKDIR /opt/
RUN git clone ${PHPIPAM_AGENT_SOURCE}.git

WORKDIR /opt/phpipam-agent
# Use system environment variables into config.php
RUN cp config.dist.php config.php && \
    sed -i -e "s/\['key'\] = .*;/\['key'\] = getenv(\"PHPIPAM_AGENT_KEY\");/" \
    -e "s/\['pingpath'\] = .*;/\['pingpath'\] = \"\/usr\/bin\/fping\";/" \
    -e "s/\['db'\]\['host'\] = \"localhost\"/\['db'\]\['host'\] = getenv(\"MYSQL_ENV_MYSQL_HOST\") ?: \"mysql\"/" \
    -e "s/\['db'\]\['user'\] = \"phpipam\"/\['db'\]\['user'\] = getenv(\"MYSQL_ENV_MYSQL_USER\") ?: \"root\"/" \
    -e "s/\['db'\]\['pass'\] = \"phpipamadmin\"/\['db'\]\['pass'\] = getenv(\"MYSQL_ENV_MYSQL_PASSWORD\")/" \
    -e "s/\['db'\]\['name'\] = \"phpipam\"/\['db'\]\['name'\] = getenv(\"MYSQL_ENV_MYSQL_DATABASE\")/" \
    -e "s/\['db'\]\['port'\] = \"3306\"/\['db'\]\['port'\] = getenv(\"MYSQL_ENV_MYSQL_PORT\")/" \
    config.php

# Setup crontab
ENV CRONTAB_FILE=/etc/cron.d/phpipam
RUN echo "* * * * * /usr/local/bin/php /opt/phpipam-agent/index.php update > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_FILE} && \
    chmod 0644 ${CRONTAB_FILE} && \
    crontab ${CRONTAB_FILE}

CMD [ "sh", "-c", "printenv > /etc/environment && cron -f" ]

