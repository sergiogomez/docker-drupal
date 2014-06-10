#!/bin/bash
if [ ! -f /var/www/sites/default/settings.php ]; then
	# Start mysql
	/usr/bin/mysqld_safe & 
	sleep 10s
	# Generate random passwords 
	DRUPAL_DB="drupal"
	MYSQL_PASSWORD=`pwgen -c -n -1 12`
	DRUPAL_PASSWORD=`pwgen -c -n -1 12`
	# This is so the passwords show up in logs. 
	echo mysql root password: $MYSQL_PASSWORD
	echo drupal password: $DRUPAL_PASSWORD
	echo $MYSQL_PASSWORD > /mysql-root-pw.txt
	echo $DRUPAL_PASSWORD > /drupal-db-pw.txt
	mysqladmin -u root password $MYSQL_PASSWORD 
	mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE drupal; GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY '$DRUPAL_PASSWORD'; FLUSH PRIVILEGES;"
	sed -i 's/www\/html/www\n\t<Directory \/var\/www>\n\t\tAllowOverride All\n\t<\/Directory>\n/' /etc/apache2/sites-available/000-default.conf
	echo "\$conf['drupal_http_request_fails'] = FALSE;" >> /var/www/sites/default/default.settings.php
	echo "apc.rfc1867 = 1" >> /etc/php5/apache2/php.ini
	a2enmod rewrite vhost_alias
	cd /var/www/
	drush site-install standard -y --account-name=admin --account-pass=admin --db-url="mysqli://drupal:${DRUPAL_PASSWORD}@localhost:3306/drupal"
	killall mysqld
	sleep 10s
fi
supervisord -n
