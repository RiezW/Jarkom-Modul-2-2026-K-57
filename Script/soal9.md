## Soal 9 - Web statis area vault (Apache + autoindex /arsip/)
   dijalankan di **obladi** dan **desmond**

1. install apache
```bash
apt-get update
apt-get install -y apache2
service apache2 start
```
container tidak pakai systemd, jadi apache dijalankan manual pakai `service`
![alt text](<Assets/No9_install apache.png>)

2. buat isi web + folder arsip <br>
   di `/arsip/` sengaja tidak ada `index.html`, supaya autoindex (directory listing) muncul
```bash
mkdir -p /var/www/vault/arsip
echo "<h1>Vault - served by $(hostname)</h1>" > /var/www/vault/index.html
for f in laporan-1.txt laporan-2.txt catatan.log; do
    echo "arsip $f dari $(hostname)" > /var/www/vault/arsip/$f
done
```

3. config virtualhost di `/etc/apache2/sites-available/vault.conf`
```apache
<VirtualHost *:80>
    ServerName vault.K57.com
    ServerAlias obladi.K57.com
    DocumentRoot /var/www/vault

    <Directory /var/www/vault/arsip>
        Options +Indexes
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/vault_error.log
    CustomLog ${APACHE_LOG_DIR}/vault_access.log combined
</VirtualHost>
```
- `ServerName` / `ServerAlias` : web diakses lewat hostname (`vault.K57.com`, `obladi.K57.com` / `desmond.K57.com`)
- `Options +Indexes` : mengaktifkan autoindex di folder `/arsip`
- `CustomLog ... combined` : log akses sendiri (dipakai lagi di soal 14)

![alt text](<Assets/No9_config vhost.png>)

4. aktifkan site
```bash
a2ensite vault
a2dissite 000-default
apache2ctl configtest
service apache2 restart
apache2ctl -S
```
`000-default` dimatikan supaya request yang tidak cocok hostname tetap masuk ke site vault
![alt text](<Assets/No9_enable site.png>)

5. script lengkap `/root/soal9.sh` (sama untuk obladi dan desmond, nama node diambil dari `$(hostname)`)
```bash
cat > /root/soal9.sh <<'SCRIPT'
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
SCRIPT
bash /root/soal9.sh
```

6. testing (sementara pakai header `Host`, karena DNS belum jadi)
```bash
curl -H "Host: vault.K57.com" http://10.92.1.4/arsip/
lynx -dump http://localhost/arsip/
```
obladi:
![alt text](<Assets/No9_test arsip obladi.png>)

desmond:
![alt text](<Assets/No9_test desmond.png>)
