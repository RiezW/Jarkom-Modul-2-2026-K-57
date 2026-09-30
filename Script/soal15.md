## Soal 15 - Path khusus di gateway: /orion (abbey, statis) dan /eternal (penny, php)

| Gateway | Path | Isi dari | Sifat |
|---------|------|----------|-------|
| **abbey** (Nginx) | `/orion` | `/var/www/orion` di abbey | murni statis, file `.php` tidak dijalankan |
| **penny** (Apache) | `/eternal` | `/var/www/eternal` di penny | file `.php` dijalankan (PHP-FPM di penny) |

kedua path dilayani langsung oleh gateway (tidak diteruskan ke backend), path lain tetap diteruskan ke load balancer seperti soal 11

### Abbey - /orion (statis)

1. buat isi folder `/var/www/orion`
```bash
mkdir -p /var/www/orion
echo "<h1>Orion - static dari abbey</h1>" > /var/www/orion/index.html
echo '<?php echo "PHP DIJALANKAN"; ?>' > /var/www/orion/test.php
ls -l /var/www/orion
cat /var/www/orion/test.php
```
`test.php` dipakai sebagai bukti: kalau statis, yang keluar adalah kode php mentah, bukan tulisan `PHP DIJALANKAN`

![alt text](<Assets/No15_%2301_buat isi orion abbey.png>)

2. tambahkan `location /orion` di `/etc/nginx/sites-available/abbey` (di atas `location /`)
```nginx
    location /orion {
        alias /var/www/orion;
        index index.html;
    }
```
- `alias /var/www/orion` : request `/orion/...` dibaca dari folder `/var/www/orion` di abbey
- tidak ada `fastcgi_pass`, jadi file `.php` hanya dikirim sebagai file biasa
- nginx memilih prefix location yang paling panjang, jadi `/orion` dilayani di sini dan path lain tetap ke `location /` (proxy ke core)

![alt text](<Assets/No15_%2303_config orion abbey.png>)

3. cek config dan restart
```bash
nginx -t
service nginx restart
```
![alt text](<Assets/No15_%2304_restart nginx abbey.png>)

4. testing dari alpha
```bash
curl http://static.K57.com/orion/
curl http://static.K57.com/orion/test.php
curl http://static.K57.com/
curl -I http://static.K57.com/orion
```
- `/orion/` : halaman orion dari abbey
- `/orion/test.php` : kode php mentah, tidak dijalankan (statis)
- `/` : tetap diteruskan ke core (oblada / molly)
- `/orion` tanpa slash : `301` ke `/orion/`

![alt text](<Assets/No15_%2306_test orion abbey.png>)

### Penny - /eternal (php)

5. install PHP-FPM di penny dan aktifkan `proxy_fcgi`
```bash
apt-get update
apt-get install -y php8.4-fpm
a2enmod proxy_fcgi
service php8.4-fpm start
ls -l /run/php/
```
`a2enconf php8.4-fpm` (saran dari notice apt) sengaja **tidak** dijalankan, karena itu mengaktifkan php di semua path penny. php hanya diaktifkan untuk `/eternal`

![alt text](<Assets/No15_%2309_install php penny selesai.png>)

![alt text](<Assets/No15_%2310_enable proxy_fcgi penny.png>)

6. buat isi folder `/var/www/eternal`
```bash
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
```
![alt text](<Assets/No15_%2311_buat isi eternal penny.png>)

7. config `/eternal` dibuat di file sendiri `/etc/apache2/eternal.conf`
```apache
ProxyPass /eternal !
Alias /eternal /var/www/eternal

<Directory /var/www/eternal>
    Require all granted
    DirectoryIndex index.php
    <FilesMatch "\.php$">
        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
    </FilesMatch>
</Directory>
```
- `ProxyPass /eternal !` : `/eternal` dikecualikan dari load balancer, jadi dilayani penny sendiri
- `Alias` : `/eternal/...` dibaca dari `/var/www/eternal`
- `FilesMatch` + `SetHandler` : file `.php` di folder ini diteruskan ke PHP-FPM lewat socket

![alt text](<Assets/No15_%2312_config eternal.png>)

8. di `penny.conf` cukup tambah 1 baris `Include`, **sebelum** `ProxyPass / balancer://vault/`
```apache
    Include /etc/apache2/eternal.conf

    ProxyPass        / balancer://vault/
    ProxyPassReverse / balancer://vault/
```
- `ProxyPass` dicek berurutan dari atas, jadi pengecualian `/eternal !` harus ada sebelum `ProxyPass /`
- config dipisah ke file sendiri supaya `penny.conf` (yang juga dipakai soal 12) hanya berubah 1 baris

![alt text](<Assets/No15_%2313_include di penny.conf.png>)

9. cek urutan, config, dan restart
```bash
grep -n "Include\|ProxyPass " /etc/apache2/sites-available/penny.conf
apache2ctl configtest
service apache2 restart
```
`Include` (baris 14) ada sebelum `ProxyPass /` (baris 16)

![alt text](<Assets/No15_%2314_cek urutan dan restart penny.png>)

10. testing dari alpha
```bash
curl http://www.K57.com/eternal/
curl http://www.K57.com/eternal/
curl http://www.K57.com/
curl http://www.K57.com/
```
- `/eternal/` : `Served by penny`, versi php tampil, tidak ada tag `<?=` lagi (php dijalankan di penny)
- `/` : tetap bergantian obladi - desmond

![alt text](<Assets/No15_%2315_test eternal penny.png>)

bukti halaman dinamis, dua request dengan jeda 3 detik menghasilkan waktu berbeda
```bash
curl http://www.K57.com/eternal/
sleep 3
curl http://www.K57.com/eternal/
```
![alt text](<Assets/No15_%2316_test eternal dinamis.png>)

### Script

11. script `/root/soal15.sh` di abbey (dijalankan setelah `soal11.sh`, menulis ulang config abbey)
```bash
cat > /root/soal15.sh <<'SCRIPT'
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
SCRIPT
```
![alt text](<Assets/No15_%2307_simpan script abbey.png>)

script `/root/soal15.sh` di penny (dijalankan setelah `soal11.sh`). `penny.conf` tidak ditulis ulang, hanya ditambah baris `Include` kalau belum ada
```bash
cat > /root/soal15.sh <<'SCRIPT'
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
SCRIPT
```
![alt text](<Assets/No15_%2318_simpan script penny.png>)
