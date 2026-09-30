#!/bin/bash
# Soal 11 - abbey: Nginx reverse proxy + load balancer ke core (oblada, molly)
apt-get update
apt-get install -y nginx

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

    location / {
        proxy_pass http://core;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/abbey /etc/nginx/sites-enabled/abbey
rm -f /etc/nginx/sites-enabled/default
nginx -t && service nginx restart
