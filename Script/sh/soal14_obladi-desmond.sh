#!/bin/bash
# Soal 14 - vault (obladi / desmond): access log mencatat IP asli client (X-Real-IP dari penny)
a2enmod remoteip

cat > /etc/apache2/sites-available/vault.conf <<EOF
<VirtualHost *:80>
    ServerName vault.K57.com
    ServerAlias $(hostname).K57.com
    DocumentRoot /var/www/vault
    RemoteIPHeader X-Real-IP
    RemoteIPInternalProxy 10.92.3.2

    <Directory /var/www/vault/arsip>
        Options +Indexes
        Require all granted
    </Directory>

    LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" realip
    ErrorLog \${APACHE_LOG_DIR}/vault_error.log
    CustomLog \${APACHE_LOG_DIR}/vault_access.log realip
</VirtualHost>
EOF

apache2ctl configtest && service apache2 restart
