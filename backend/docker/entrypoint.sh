#!/bin/sh
# Start container: Apache mendengarkan $PORT (Render), cache konfigurasi, migrasi, lalu jalan.
set -e

sed -ri "s/^Listen .*/Listen ${PORT:-10000}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${PORT:-10000}>/" /etc/apache2/sites-available/000-default.conf

php artisan config:cache
php artisan route:cache
php artisan storage:link 2>/dev/null || true
# Migrasi lewat koneksi langsung (DB_URL_UNPOOLED); aplikasi memakai DB_URL (pooled).
php artisan migrate --force --database=pgsql_direct

exec apache2-foreground
