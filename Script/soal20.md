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

3. bikin auto start di obladi, desmond, oblada, molly <br>
   /root/script.sh (yang dijalankan saat boot lewat `up bash /root/script.sh`) ditambah baris PATH dan service <br>
   obladi dan desmond :
   ```bash
   cat > /root/script.sh <<'EOF'
   #!/bin/bash
   export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

   echo "nameserver 10.92.1.2" > /etc/resolv.conf
   echo "nameserver 10.92.1.3" >> /etc/resolv.conf
   echo "nameserver 192.168.122.1" >> /etc/resolv.conf
   service apache2 start
   EOF
   cat /root/script.sh
   ```
   oblada dan molly :
   ```bash
   cat > /root/script.sh <<'EOF'
   #!/bin/bash
   export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

   echo "nameserver 10.92.1.2" > /etc/resolv.conf
   echo "nameserver 10.92.1.3" >> /etc/resolv.conf
   echo "nameserver 192.168.122.1" >> /etc/resolv.conf
   service php8.4-fpm start
   service nginx start
   EOF
   cat /root/script.sh
   ```
   perubahan dari script.sh sebelumnya (soal 4) :
   ```diff
     #!/bin/bash
   + export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
     echo "nameserver 10.92.1.2" > /etc/resolv.conf
     echo "nameserver 10.92.1.3" >> /etc/resolv.conf
     echo "nameserver 192.168.122.1" >> /etc/resolv.conf
   + service apache2 start        # obladi, desmond
   + service php8.4-fpm start     # oblada, molly
   + service nginx start          # oblada, molly
   ```
   kenapa perlu baris PATH : saat boot, script dijalankan dengan PATH milik GNS3 yang mendahulukan busybox. `ps` versi busybox salah membaca pid file lama (sisa sebelum restart), jadi `service apache2 start` mengira apache sudah jalan dan tidak menyalakannya. Dengan PATH normal, `service` memakai `ps` asli dan service menyala

4. uji coba setelah node di restart <br>
   di node
   ```bash
   service apache2 status        # obladi, desmond
   service php8.4-fpm status     # oblada, molly
   service nginx status          # oblada, molly
   ```
   dari client
   ```bash
   curl -H "Host: www.K57.com" http://10.92.3.2/
   curl -H "Host: www.K57.com" http://10.92.3.2/
   curl -H "Host: core.K57.com" http://10.92.1.6/profil
   curl -H "Host: core.K57.com" http://10.92.1.7/profil
   ```
   www bergantian obladi - desmond, core menampilkan halaman profil dari oblada dan molly


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