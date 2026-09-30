#!/bin/bash
# Soal 15 - penny: path /eternal menyajikan /var/www/eternal dan menjalankan php
apt-get update
apt-get install -y php8.4-fpm
a2enmod proxy_fcgi
service php8.4-fpm start

mkdir -p /var/www/eternal
cat > /var/www/eternal/index.php <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Eternal</title></head>
<body>
<h1>Eternal - PHP di penny</h1>
<p>Served by <?= gethostname() ?></p>
<p>Waktu server: <?= date('Y-m-d H:i:s') ?></p>
<p>PHP versi <?= PHP_VERSION ?></p>
</body>
</html>
EOF

cat > /etc/apache2/eternal.conf <<'EOF'
ProxyPass /eternal !
Alias /eternal /var/www/eternal

<Directory /var/www/eternal>
    Require all granted
    DirectoryIndex index.php
    <FilesMatch "\.php$">
        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
    </FilesMatch>
</Directory>
EOF

# tambah 1 baris Include di penny.conf (hanya kalau belum ada), sebelum ProxyPass balancer
grep -q "eternal.conf" /etc/apache2/sites-available/penny.conf || \
sed -i '/ProxyPass *\/ balancer/i\    Include /etc/apache2/eternal.conf' /etc/apache2/sites-available/penny.conf

apache2ctl configtest && service apache2 restart
