#!/bin/bash
# Soal 11 - penny: Apache reverse proxy + load balancer ke vault (obladi, desmond)
apt-get update
apt-get install -y apache2
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers

cat > /etc/apache2/sites-available/penny.conf <<'EOF'
<VirtualHost *:80>
    ServerName www.K57.com
    ServerAlias K57.com

    <Proxy "balancer://vault">
        BalancerMember http://10.92.1.4
        BalancerMember http://10.92.1.5
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPreserveHost On
    RequestHeader set X-Real-IP "expr=%{REMOTE_ADDR}"

    ProxyPass        / balancer://vault/
    ProxyPassReverse / balancer://vault/

    ErrorLog ${APACHE_LOG_DIR}/penny_error.log
    CustomLog ${APACHE_LOG_DIR}/penny_access.log combined
</VirtualHost>
EOF

a2ensite penny
a2dissite 000-default
apache2ctl configtest && service apache2 restart
