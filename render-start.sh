#!/bin/sh
set -eu

PORT="${PORT:-10000}"

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

if [ -z "${APP_KEY:-}" ]; then
  if [ -f .env ] && grep -q '^APP_KEY=$' .env; then
    APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
    export APP_KEY
    sed -i "s|^APP_KEY=$|APP_KEY=${APP_KEY}|" .env
  elif [ ! -f .env ]; then
    APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
    export APP_KEY
    printf 'APP_KEY=%s\n' "$APP_KEY" > .env
  fi
fi

php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true
php artisan package:discover --ansi || true

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  php artisan migrate --force
fi

if [ "${RUN_SEEDERS:-true}" = "true" ]; then
  php artisan db:seed --force
fi

exec php -d variables_order=EGPCS artisan serve --host=0.0.0.0 --port="$PORT"
