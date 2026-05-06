#!/bin/sh
set -eu

PORT="${PORT:-10000}"

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true
php artisan package:discover --ansi || true

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
  php artisan migrate --force
fi

exec php -d variables_order=EGPCS artisan serve --host=0.0.0.0 --port="$PORT"
