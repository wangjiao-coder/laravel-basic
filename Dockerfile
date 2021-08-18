FROM registry.cn-qingdao.aliyuncs.com/huiji/laravel-production:2.7
# Install dependencies
WORKDIR /var/www/html
COPY composer.json composer.json
COPY composer.lock composer.lock
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader && rm -rf /root/.composer
COPY . .
# Finish composer
RUN mv .env.example .env
RUN composer dump-autoload --no-scripts --no-dev --optimize
RUN chown -R www-data /var/www/html/public && chown -R www-data /var/www/html/storage
CMD ["* * * * * /usr/local/bin/php /var/www/html/artisan schedule:run >> /dev/null 2>&1"]
