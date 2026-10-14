# Backend naura untuk Render (paket gratis). Lihat docs/deploy.md.
FROM php:8.3-apache

# Ekstensi: PostgreSQL + zip (composer). mbstring/openssl/curl/fileinfo sudah ada di image.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev libzip-dev unzip \
    && docker-php-ext-install pdo_pgsql pgsql zip opcache \
    && rm -rf /var/lib/apt/lists/*

# Apache: document root ke public/, mod_rewrite untuk routing Laravel.
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf \
    && a2enmod rewrite \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html

# Dependency dulu agar layer ini ter-cache selama composer.lock tidak berubah.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist --no-autoloader

COPY . .
RUN composer dump-autoload --optimize --no-dev \
    && rm -f .env bootstrap/cache/*.php \
    && chown -R www-data:www-data storage bootstrap/cache

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV PORT=10000
EXPOSE 10000
ENTRYPOINT ["entrypoint.sh"]
