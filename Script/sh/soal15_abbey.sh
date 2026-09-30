#!/bin/bash
# Soal 15 - abbey: path /orion menyajikan /var/www/orion secara statis (tanpa php)
mkdir -p /var/www/orion
echo "<h1>Orion - static dari abbey</h1>" > /var/www/orion/index.html
echo '<?php echo "PHP DIJALANKAN"; ?>' > /var/www/orion/test.php

cat > /etc/nginx/sites-available/abbey <<'EOF'
upstream core {
    zone core 64k;
    server 10.92.1.6;
    server 10.92.1.7;
}

server {
    listen 80;
    server_name static.K57.com;

    access_log /var/log/nginx/abbey_access.log;
    error_log  /var/log/nginx/abbey_error.log;

    location /orion {
        alias /var/www/orion;
        index index.html;
    }

    location / {
        proxy_pass http://core;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

nginx -t && service nginx restart
