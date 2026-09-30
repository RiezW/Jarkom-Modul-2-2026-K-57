1. bikin auto start di penny dan abbey <br>
   penny : 
   ```bash
   echo "service apache2 start" >> /etc/bash.bashrc
   ```
   abbey :
   ```bash
   echo "service apache2 start" >> /etc/bash.bashrc
   ```

2. uji coba dengan node lainnya <br>
   Uji Basic Auth penny
   ```bash
   curl -i -u prabs:pakar_pinter_jadi_gob*** http://10.92.3.2/admin/
   ```
   Uji Redirect 301 penny
   ```bash
   curl -I http://10.92.3.2
   ```
   Uji Redirect 302 abbey
   ```bash
   curl -I http://10.92.2.2
   ```


   Note : 

1. upgrade penny
   ```bash
   nano /etc/apache2/sites-available/000-default.conf
   ```
   ```bash
    <VirtualHost *:80>
        ServerName penny.K57.com
        ServerAlias 10.92.3.2
        DocumentRoot /var/www/html

        RewriteEngine On
        # Kecualikan folder /admin agar tidak di-redirect
        RewriteCond %{REQUEST_URI} !^/admin [NC]
        RewriteRule ^(.*)$ http://www.K57.com/$1 [R=301,L]

        <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        <Directory /var/www/html/admin>
            AuthType Basic
            AuthName "Restricted Admin Area"
            AuthUserFile /etc/apache2/.htpasswd
            Require valid-user
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
    ```
    ```bash
    a2enmod rewrite
    service apache2 restart
    ```