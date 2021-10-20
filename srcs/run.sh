#!/bin/bash
cp /tmp/default /etc/nginx/sites-available/default


openssl req -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=Lee/CN=localhost" -keyout localhost.dev.key -out localhost.dev.crt 
mv localhost.dev.crt etc/ssl/certs/
mv localhost.dev.key etc/ssl/private/
chmod 600 etc/ssl/certs/localhost.dev.crt etc/ssl/private/localhost.dev.key

wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz
tar -xvf phpMyAdmin-5.0.2-all-languages.tar.gz
mv phpMyAdmin-5.0.2-all-languages phpmyadmin
mv phpmyadmin/ /var/www/html/
cp /tmp/config.inc.php /var/www/html/phpmyadmin/config.inc.php

wget -c https://wordpress.org/latest.tar.gz
tar -xvf latest.tar.gz
mv wordpress/ /var/www/html/
cp /tmp/wp-config.php /var/www/html/wordpress/wp-config.php

chown -R www-data:www-data /var/www/*
chmod -R 755 /var/www/*

service nginx start
service mysql start
mysql --execute "CREATE USER 'yoonsung'@'localhost' IDENTIFIED BY 'abcd1234';CREATE DATABASE wordpress;GRANT ALL PRIVILEGES ON *.* TO 'yoonsung'@'localhost' WITH GRANT OPTION;FLUSH PRIVILEGES;"
mysql < var/www/html/phpmyadmin/sql/create_tables.sql
service php7.3-fpm start

service nginx restart
sleep inf

