#!/bin/bash
# Soal 14 - core (oblada / molly): access log mencatat IP asli client (X-Real-IP dari abbey)
cat > /etc/nginx/sites-available/core <<EOF
server {
    listen 80;
    server_name core.K57.com $(hostname).K57.com;
    root /var/www/core;
    index index.php;
    set_real_ip_from 10.92.2.2;
    real_ip_header X-Real-IP;

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

nginx -t && service nginx restart
