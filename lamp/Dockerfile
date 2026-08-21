ARG PHP_IMAGE=php:7.3-apache
FROM ${PHP_IMAGE}

# mariadb-client for CLI access to MySQL
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  mariadb-client \
  && rm -rf /var/lib/apt/lists/*

# pdo_mysql extension
RUN docker-php-ext-install pdo_mysql
