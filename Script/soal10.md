## Soal 10 - Web dinamis area core (Nginx + PHP-FPM + clean URL /profil)
   dijalankan di **oblada** dan **molly**

1. install nginx dan php-fpm
```bash
apt-get update
apt-get install -y nginx php8.4-fpm
service php8.4-fpm start
service nginx start
```
nginx tidak bisa menjalankan php sendiri, request `.php` diteruskan ke PHP-FPM lewat socket `/run/php/php8.4-fpm.sock`, jadi dua service ini harus jalan
![alt text](<Assets/No10_%2302_install nginx php.png>)

2. buat halaman beranda (`index.php`) dan profil (`profil.php`)
```bash
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
```
- `gethostname()` : menampilkan node yang melayani request (oblada / molly)
- `date()` : waktu server, berubah setiap request, bukti halaman dibuat oleh PHP (dinamis)
- `<<'EOF'` pakai tanda kutip supaya `<?= ?>` tidak diproses oleh shell

![alt text](<Assets/No10_%2304_buat halaman php.png>)

3. config nginx di `/etc/nginx/sites-available/core`
```nginx
server {
    listen 80;
    server_name core.K57.com oblada.K57.com;
    root /var/www/core;
    index index.php;

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
- `server_name` : web diakses lewat hostname (`core.K57.com`, `oblada.K57.com` / `molly.K57.com`)
- `try_files $uri $uri/ $uri.php` : aturan rewrite clean URL, `/profil` tidak ada sebagai file / folder, jadi nginx mencoba `/profil.php` secara internal, URL di browser tetap `/profil`
- `location ~ \.php$` : semua file `.php` diteruskan ke PHP-FPM
- `access_log` : log akses sendiri (dipakai lagi di soal 14)

![alt text](<Assets/No10_%2305_config nginx.png>)

4. aktifkan site
```bash
ln -sf /etc/nginx/sites-available/core /etc/nginx/sites-enabled/core
rm -f /etc/nginx/sites-enabled/default
nginx -t
service nginx restart
```
site `default` dimatikan supaya request yang tidak cocok hostname tetap masuk ke site core
![alt text](<Assets/No10_%2306_enable site.png>)

5. script lengkap `/root/soal10.sh` (sama untuk oblada dan molly, nama node diambil dari `$(hostname)`)
```bash
cat > /root/soal10.sh <<'SCRIPT'
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
SCRIPT
bash /root/soal10.sh
```
variabel nginx (`$uri`, `$query_string`) ditulis `\$` supaya tidak diganti oleh shell, sedangkan `$(hostname)` sengaja diganti shell menjadi nama node

6. testing (sementara pakai header `Host`, karena DNS belum jadi)
```bash
curl -H "Host: core.K57.com" http://localhost/
curl -H "Host: core.K57.com" http://localhost/profil
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: core.K57.com" http://localhost/tidakada
curl -H "Host: core.K57.com" http://10.92.1.6/profil
```
- `/profil` (tanpa `.php`) : 200, halaman profil tampil
- `/tidakada` : 404
- dari node lain (penny) juga bisa diakses

oblada:
![alt text](<Assets/No10_%2307_test oblada.png>)

molly:
![alt text](<Assets/No10_%2313_test molly.png>)
