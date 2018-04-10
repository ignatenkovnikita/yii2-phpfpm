FROM php:7-fpm

# Install modules
RUN apt-get update -yqq
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libicu-dev \
        librabbitmq-dev \
                --no-install-recommends

RUN apt-get install -y libpq-dev
RUN apt-get install git zlib1g-dev zip openssl  libc-client-dev libkrb5-dev g++ libpq-dev libbz2-dev libfontconfig -yqq

RUN docker-php-ext-install  zip intl mbstring pdo_mysql pdo_pgsql exif bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

RUN docker-php-ext-install bz2

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-install imap

RUN printf "\n" | pecl install channel://pecl.php.net/amqp-1.7.0alpha2 && echo extension=amqp.so > /usr/local/etc/php/conf.d/amqp.ini


RUN pecl install -o -f xdebug \
    && rm -rf /tmp/pear
RUN docker-php-ext-enable xdebug

COPY ./php.ini /usr/local/etc/php/
COPY ./www.conf /usr/local/etc/php/

RUN apt-get purge -y g++ \
    && apt-get autoremove -y \
    && rm -r /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN eval $(ssh-agent -s)
RUN mkdir -p ~/.ssh

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin && \
        echo "alias composer='composer'" >> /root/.bashrc && \
        composer

# Install all project dependencies
RUN  composer global require "fxp/composer-asset-plugin:^1.4.2"
RUN  composer global require hirak/prestissimo

RUN usermod -u 1000 www-data

EXPOSE 9000
CMD ["php-fpm"]
