#!/bin/bash
apt-get update
apt-get install -y apache2

mkdir -p /var/www/vault/arsip
echo "<h1>Vault - served by $(hostname)</h1>" > /var/www/vault/index.html
for f in laporan-1.txt laporan-2.txt catatan.log; do
    echo "arsip $f dari $(hostname)" > /var/www/vault/arsip/$f
done

cat > /etc/apache2/sites-available/vault.conf <<EOF
<VirtualHost *:80>
    ServerName vault.K57.com
    ServerAlias $(hostname).K57.com
    DocumentRoot /var/www/vault

    <Directory /var/www/vault/arsip>
        Options +Indexes
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/vault_error.log
    CustomLog \${APACHE_LOG_DIR}/vault_access.log combined
</VirtualHost>
EOF

a2ensite vault
a2dissite 000-default
apache2ctl configtest && service apache2 restart
