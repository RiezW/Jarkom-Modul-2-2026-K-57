## Soal 14 - Access log mencatat IP asli client
   dijalankan di backend **obladi**, **desmond** (Apache) dan **oblada**, **molly** (Nginx)

sejak soal 11, semua request ke backend datang dari proxy (penny / abbey), jadi access log backend hanya mencatat IP proxy. IP asli client ada di header `X-Real-IP` yang dikirim proxy. Backend diatur supaya memakai header itu, tetapi **hanya kalau request datang dari proxy-nya sendiri**

| Backend | Web server | Proxy di depannya | Cara |
|---------|-----------|-------------------|------|
| obladi, desmond | Apache | penny `10.92.3.2` | `mod_remoteip` |
| oblada, molly | Nginx | abbey `10.92.2.2` | `set_real_ip_from` + `real_ip_header` |

client untuk testing: **alpha** (`10.92.4.2`)

### Sebelum (masalah)

request dari alpha ke `www.K57.com` (lewat penny)
```bash
curl http://www.K57.com/
curl http://www.K57.com/
```
![alt text](<Assets/No14_%2303_request alpha ke www sebelum.png>)

log obladi mencatat `10.92.3.2` (penny), bukan alpha
```bash
tail -n 3 /var/log/apache2/vault_access.log
```
![alt text](<Assets/No14_%2304_log obladi sebelum.png>)

log oblada mencatat `10.92.2.2` (abbey), bukan alpha
```bash
tail -n 2 /var/log/nginx/core_access.log
```
![alt text](<Assets/No14_%2313_log oblada sebelum.png>)

### Area vault (Apache)

1. aktifkan modul `remoteip`
```bash
a2enmod remoteip
```

2. tambahkan di `/etc/apache2/sites-available/vault.conf`
```apache
<VirtualHost *:80>
    ServerName vault.K57.com
    ServerAlias obladi.K57.com
    DocumentRoot /var/www/vault
    RemoteIPHeader X-Real-IP
    RemoteIPInternalProxy 10.92.3.2

    <Directory /var/www/vault/arsip>
        Options +Indexes
        Require all granted
    </Directory>

    LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" realip
    ErrorLog ${APACHE_LOG_DIR}/vault_error.log
    CustomLog ${APACHE_LOG_DIR}/vault_access.log realip
</VirtualHost>
```
- `RemoteIPHeader X-Real-IP` : IP asli client diambil dari header `X-Real-IP`
- `RemoteIPInternalProxy 10.92.3.2` : header hanya dipercaya kalau request datang dari penny, supaya client tidak bisa memalsukan IP
- `LogFormat ... realip` : sama seperti format `combined`, tetapi diawali `%a` (IP client setelah diganti oleh `mod_remoteip`)
- `CustomLog ... realip` : access log memakai format `realip`
- di desmond sama, hanya `ServerAlias desmond.K57.com`

![alt text](<Assets/No14_%2305_config remoteip obladi.png>)

3. cek config dan restart
```bash
apache2ctl configtest
service apache2 restart
```

4. hasil, request dari alpha sekarang tercatat `10.92.4.2`

obladi:
![alt text](<Assets/No14_%2306_log obladi sesudah.png>)

desmond:
![alt text](<Assets/No14_%2311_log desmond sesudah.png>)

### Area core (Nginx)

5. tambahkan dua baris di `/etc/nginx/sites-available/core` (di dalam `server`)
```nginx
server {
    listen 80;
    server_name core.K57.com oblada.K57.com;
    root /var/www/core;
    index index.php;
    set_real_ip_from 10.92.2.2;
    real_ip_header X-Real-IP;

    access_log /var/log/nginx/core_access.log;
    error_log  /var/log/nginx/core_error.log;

    location / {
        try_files $uri $uri/ $uri.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
```
- `set_real_ip_from 10.92.2.2` : header hanya dipercaya dari abbey
- `real_ip_header X-Real-IP` : IP client diambil dari header `X-Real-IP`
- format log default nginx sudah memakai `$remote_addr`, dan nilai itu yang diganti oleh modul realip, jadi format log tidak perlu diubah
- di molly sama, hanya `server_name core.K57.com molly.K57.com`

![alt text](<Assets/No14_%2314_config realip oblada.png>)

6. cek config dan restart
```bash
nginx -t
service nginx restart
```

7. hasil, request dari alpha ke `static.K57.com` sekarang tercatat `10.92.4.2`

oblada:
![alt text](<Assets/No14_%2317_log oblada sesudah.png>)

molly:
![alt text](<Assets/No14_%2321_log molly sesudah.png>)

### Script

8. script `/root/soal14.sh` di obladi dan desmond (dijalankan setelah `soal9.sh`)
```bash
cat > /root/soal14.sh <<'SCRIPT'
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
SCRIPT
```

script `/root/soal14.sh` di oblada dan molly (dijalankan setelah `soal10.sh`)
```bash
cat > /root/soal14.sh <<'SCRIPT'
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
SCRIPT
```
script menulis ulang seluruh config (config soal 9 / 10 + tambahan soal 14), jadi urutannya harus `soal9.sh` / `soal10.sh` dulu, baru `soal14.sh`

![alt text](<Assets/No14_%2322_simpan script obladi.png>)

![alt text](<Assets/No14_%2324_simpan script oblada molly.png>)
