#!/bin/bash
# Soal 10 - core (oblada / molly): Nginx + PHP-FPM + clean URL /profil
apt-get update
apt-get install -y nginx php8.4-fpm

mkdir -p /var/www/core

cat > /var/www/core/index.php <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Core - Beranda</title></head>
<body>
<h1>Beranda</h1>
<p>Served by <?= gethostname() ?></p>
<p>Waktu server: <?= date('Y-m-d H:i:s') ?></p>
<a href="/profil">Lihat Profil</a>
</body>
</html>
EOF

cat > /var/www/core/profil.php <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Core - Profil</title></head>
<body>
<h1>Profil</h1>
<p>Kelompok K57 - Jarkom Modul 2</p>
<p>Served by <?= gethostname() ?></p>
<a href="/">Kembali ke Beranda</a>
</body>
</html>
EOF

cat > /etc/nginx/sites-available/core <<EOF
server {
    listen 80;
    server_name core.K57.com $(hostname).K57.com;
    root /var/www/core;
    index index.php;

    access_log /var/log/nginx/core_access.log;
    error_log  /var/log/nginx/core_error.log;

    location / {
        try_files \$uri \$uri/ \$uri.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/core /etc/nginx/sites-enabled/core
rm -f /etc/nginx/sites-enabled/default
service php8.4-fpm start
nginx -t && service nginx restart
