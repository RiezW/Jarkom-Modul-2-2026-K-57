1. di penny rewrite apache
   ```bash
   a2enmod rewrite
   ```
   configure conf lagi
   ```bash
   nano /etc/apache2/sites-available/000-default.conf
   ```
   ```bash
    <VirtualHost *:80>
        ServerName penny.K57.com
        ServerAlias 10.92.3.2
        DocumentRoot /var/www/html

        # Redirect permanen (301) ke www.K57.com
        Redirect 301 / http://www.K57.com/

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
    restart apache
    ```bash
    service apache2 restart
    ```

2. test di alpha
   ```bash
    curl -I http://penny.K57.com
    curl -I http://10.92.3.2
    ```
    ![alt text](<Assets/No13_test penny di alpha.png>)

3. konfigurasi abbey <br>
   install apache
   ```bash
    apt-get update
    apt-get install -y apache2
    ```
   edit config
   ```bash
   nano /etc/apache2/sites-available/000-default.conf
    ```
    isi konfigurasi
    ```bash
    <VirtualHost *:80>
        ServerName abbey.K57.com
        ServerAlias 10.92.2.2
        DocumentRoot /var/www/html

        # Redirect sementara (302) ke static.K57.com
        Redirect 302 / http://static.K57.com/

        <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
    ```
    save and restart
    ```bash
    a2ensite 000-default.conf
    service apache2 restart
    ```
    kalau misal gagal coba kill port 80 yg jalan
    ```bash
    service nginx stop 2>/dev/null
    killall -9 apache2 nginx httpd 2>/dev/null
    ```
    lalu restart lagi
    ```bash
    service apache2 start
    ```

4. test abbey di alpha
   ```bash
    curl -I http://abbey.K57.com
    curl -I http://10.92.2.2
    ```
    ![alt text](<Assets/No13_test penny di alpha.png>)