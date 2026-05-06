FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

COPY . .
RUN composer dump-autoload --optimize --no-dev

FROM node:22-alpine AS frontend

WORKDIR /app

COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY resources ./resources
COPY public ./public
COPY vite.config.js ./
RUN npm run build

FROM php:8.4-cli-alpine

WORKDIR /app

RUN apk add --no-cache \
    $PHPIZE_DEPS \
    libzip \
    libpq \
    libpq-dev \
    oniguruma \
    oniguruma-dev \
    sqlite-libs \
    postgresql-client \
    zip \
    unzip \
    git \
    curl \
    bash \
    && docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pdo_mysql \
    bcmath \
    mbstring \
    pcntl \
    && apk del --no-network $PHPIZE_DEPS oniguruma-dev libpq-dev

COPY --from=vendor /app /app
COPY --from=frontend /app/public/build /app/public/build

RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

COPY render-start.sh /usr/local/bin/render-start.sh
RUN chmod +x /usr/local/bin/render-start.sh

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stack \
    LOG_LEVEL=error \
    DB_CONNECTION=pgsql \
    DB_SSLMODE=require \
    SESSION_DRIVER=cookie \
    SESSION_SECURE_COOKIE=true \
    FILESYSTEM_DISK=local \
    QUEUE_CONNECTION=sync \
    CACHE_STORE=file \
    RUN_MIGRATIONS=true \
    RUN_SEEDERS=true \
    PORT=10000

EXPOSE 10000

CMD ["render-start.sh"]
