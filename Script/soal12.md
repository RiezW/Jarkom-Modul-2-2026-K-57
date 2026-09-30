1. install apache di client penny
   ```bash
    apt-get update
    apt-get install -y apache2-utils
    ```
    ![alt text](<Assets/No12_apache install.png>)

2. membuat kredensial di penny <br>
   jalan di console 
   ```bash
   htpasswd -bc /etc/apache2/.htpasswd prabs pakar_pinter_jadi_gob***
   ```
   aktifin authentication apache
   ```bash
   a2enmod auth_basic
   ```
   ![alt text](<Assets/No12_set kredensial dan enabled apache.png>)

3. configure virtual host apache
   ```bash
   nano /etc/apache2/sites-available/000-default.conf
   ```
   configure dalamnya tambahkan bagian ini
   ```bash
    <VirtualHost *:80>
        ServerName penny.K57.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

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

4. buat folder dan dokumen adminnn <br>
   pastikan apache aktif
   ```bash
   a2ensite 000-default.conf
   ```
   bikin folder dan 
   ```bash
   mkdir -p /var/www/html/admin
    echo "Dokumen Rahasia Sindikat Penny" > /var/www/html/admin/index.html
    ```
    kasih izin
    ```bash
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html    
    ```
    restart apache
    ```bash
    service apache2 restart
    ```

5. verifikasi dan pengujian (coba seperti biasa di client aplha)
   ```bash
   curl -i http://penny.K57.com/admin/
   ```
   ![alt text](<Assets/No12_test tanpa kredensial.png>)
   akses dengan kredensial
   ```bash
   curl -i -u prabs:pakar_pinter_jadi_gob*** http://penny.K57.com/admin/
   ```
   ![alt text](<Assets/No12_with kredensial.png>)