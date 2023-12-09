# Base image
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    curl

# Install Node Version Manager (nvm)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Source nvm and install Node.js and npm
RUN bash -c "source /root/.bashrc && nvm install 14 && nvm use 14"

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip exif pcntl bcmath gd

# Enable Apache rewrite module
RUN a2enmod rewrite

# Set the document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install Composer
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# Copy only composer files and install dependencies first
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader

# Copy the rest of the application files
COPY . .

# Install Yarn
RUN bash -c "source /root/.bashrc && npm install -g yarn"

# Install dependencies using Yarn
RUN bash -c "source /root/.bashrc && yarn install"

# Generate optimized autoloader
RUN composer dump-autoload --optimize

# Set permissions
RUN chown -R www-data:www-data storage bootstrap/cache

# Run database migrations and seeders (if needed)
# RUN php artisan migrate --seed

# Expose port 80
EXPOSE 80

# Start the Apache server
CMD ["apache2-foreground"]
