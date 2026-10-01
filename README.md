# Jarkom-Modul-2-2026-K-57

| | |
|---|---|
| **Nama** | : Riezco Eka Bayu Witantra & Sulthan Daffa Al Hasyimi |
| **NRP** | : 5027251057 & 5027251091 |
| **Kelompok** | : K-57 |
| **Mata Kuliah** | : JarKom |

---

## I. Gambaran Umum

Praktikum Modul 2 membangun jaringan **The Mesh** di GNS3 (project `K-57-MODUL-2`) dengan domain **K57.com**. Seluruh node memakai image Docker `ardhptr21/debinet:latest` (Debian 13). Pekerjaan dibagi menjadi empat bagian besar:

| Bagian | Soal | Isi |
|---|---|---|
| Jaringan dasar | 1 - 3 | IP address, NAT ke internet, routing antar subnet, resolver |
| DNS | 4 - 8, 17 - 19 | DNS master (prab) dan slave (tedd), A record, CNAME, reverse zone, TXT, TTL, CNAME eksternal |
| Web dan gerbang | 9 - 16 | Web statis (Apache), web dinamis (Nginx + PHP-FPM), reverse proxy dan load balancing, basic auth, redirect kanonik, IP asli di log, path khusus, benchmark |
| Persistensi | 20 | Service dan konfigurasi tetap berjalan setelah node di-restart |

### Struktur Repository

| Lokasi | Isi |
|---|---|
| `README.md` | Laporan ini |
| `Script/soalN.md` | Langkah pengerjaan lengkap per soal (perintah, konfigurasi, penjelasan, screenshot) |
| `Script/sh/` | Seluruh script `.sh` per soal per node, diambil dari `soalN.md` |
| `Script/Assets/` | Screenshot dokumentasi (format nama `NoXX_#xx_deskripsi.png`) |

Semua script instalasi dan konfigurasi disimpan di `/root` pada node masing-masing.

---

## II. Topologi dan Pembagian IP

![Topologi](<Script/Assets/No1_topologi.png>)

Router **rootkid** memiliki 6 interface: `eth0` ke NAT (internet) dan `eth1` - `eth5` ke lima gerbang (switch). Koneksi hasil pembacaan GNS3:

| Interface rootkid | Switch | Node di belakangnya | Subnet |
|---|---|---|---|
| `eth0` | NAT1 | (internet, DHCP) | `192.168.122.0/24` |
| `eth1` | Switch1 (bercabang ke Switch2 dan Switch3) | Switch2: prab, tedd. Switch3: obladi, desmond, oblada, molly | `10.92.1.0/24` |
| `eth2` | Switch4 | abbey | `10.92.2.0/24` |
| `eth3` | Switch5 | penny | `10.92.3.0/24` |
| `eth4` | Switch6 | alpha, beta, gamma | `10.92.4.0/24` |
| `eth5` | Switch7 | delta, epsilon | `10.92.5.0/24` |

| Node | Peran | IP | Gateway |
|---|---|---|---|
| rootkid | Router + NAT | `10.92.1.1` - `10.92.5.1` | DHCP (eth0) |
| prab | DNS master (ns1) | `10.92.1.2` | `10.92.1.1` |
| tedd | DNS slave (ns2) | `10.92.1.3` | `10.92.1.1` |
| obladi | Web statis (area vault) | `10.92.1.4` | `10.92.1.1` |
| desmond | Web statis (area vault) | `10.92.1.5` | `10.92.1.1` |
| oblada | Web dinamis (area core) | `10.92.1.6` | `10.92.1.1` |
| molly | Web dinamis (area core) | `10.92.1.7` | `10.92.1.1` |
| abbey | Gerbang `static.K57.com` (Nginx) | `10.92.2.2` | `10.92.2.1` |
| penny | Gerbang `www.K57.com` (Apache) | `10.92.3.2` | `10.92.3.1` |
| alpha, beta, gamma | Client | `10.92.4.2` - `10.92.4.4` | `10.92.4.1` |
| delta, epsilon | Client | `10.92.5.2` - `10.92.5.3` | `10.92.5.1` |

---

## III. Pembahasan per Nomor Soal

### Nomor 1 - Topologi dan Konfigurasi IP

**Permintaan Soal**
rootkid menghubungkan seluruh entitas ke lima switch. Setiap node diberi IP address dan default gateway sesuai pembagian subnet.

**Konfigurasi yang Digunakan**
```bash
# rootkid - Network Configuration (GNS3)
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.92.1.1
    netmask 255.255.255.0
# eth2 - eth5 sama, dengan address 10.92.2.1 - 10.92.5.1

# Contoh client (prab)
auto eth0
iface eth0 inet static
    address 10.92.1.2
    netmask 255.255.255.0
    gateway 10.92.1.1
```

**Langkah Menjalankan**
1. Susun topologi: NAT1 ke `eth0` rootkid, `eth1` - `eth5` ke Switch1, Switch4, Switch5, Switch6, Switch7. Switch1 bercabang ke Switch2 (DNS) dan Switch3 (web backend).
2. Isi konfigurasi IP setiap node lewat **Configure > Network configuration** di GNS3.
3. Konfigurasi seluruh node ada di [`Script/soal1.md`](Script/soal1.md).

---

### Nomor 2 - NAT ke Internet

**Permintaan Soal**
Interface WAN rootkid aktif dan NAT meneruskan lalu lintas keluar untuk seluruh alamat internal.

**Konfigurasi yang Digunakan** ([`soal02_rootkid.sh`](Script/sh/soal02_rootkid.sh))
```bash
sysctl -q -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
# ... eth2 - eth5 sama
```

**Langkah Menjalankan**
1. Script disimpan di `/root/script.sh` rootkid dan dijalankan otomatis lewat baris `up bash /root/script.sh` pada `eth0`.
2. `ip_forward` mengaktifkan routing, `MASQUERADE` menyamarkan IP internal menjadi IP rootkid saat keluar ke internet.
3. Verifikasi dengan `iptables -t nat -L -v -n` di rootkid dan `ping 8.8.8.8` dari client.

**Bukti / Dokumentasi**
> ![Ping dari client](<Script/Assets/No2_test ping dari client.png>)
>
> ![Ping internet obladi](<Script/Assets/No02_%2302_ping internet obladi.png>)

---

### Nomor 3 - Routing Antar Subnet dan Resolver

**Permintaan Soal**
Seluruh entitas dapat saling terhubung lintas subnet lewat rootkid, dan setiap host non-router memakai resolver `192.168.122.1`.

**Konfigurasi yang Digunakan** ([`soal03_client.sh`](Script/sh/soal03_client.sh))
```bash
#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```
Pada Network configuration setiap node ditambahkan `up bash /root/script.sh` di bawah `gateway`, sehingga resolver ditulis ulang setiap node menyala.

**Bukti / Dokumentasi**
> ![Ping DNS](<Script/Assets/No3_ping dns.png>)
>
> ![Ping antar client](<Script/Assets/No3_ping antar client.png>)
>
> ![Ping antar subnet obladi](<Script/Assets/No03_%2303_ping antar subnet obladi.png>)

---

### Nomor 4 - DNS Master (prab) dan Slave (tedd)

**Permintaan Soal**
prab menjadi authoritative untuk zone `K57.com` dengan SOA ke `prab.K57.com`, NS untuk prab dan tedd, A record untuk prab, tedd, dan apex domain. tedd menjadi slave.

**Konfigurasi yang Digunakan** ([`soal04_prab.sh`](Script/sh/soal04_prab.sh), [`soal04_tedd.sh`](Script/sh/soal04_tedd.sh), [`soal04_client.sh`](Script/sh/soal04_client.sh))
```bash
# prab - named.conf.local
zone "K57.com" {
    type master;
    file "/etc/bind/jarkom/K57.com";
    notify yes;
    also-notify { 10.92.1.3; };
    allow-transfer { 10.92.1.3; };
};

# prab - zone K57.com
$TTL 604800
@ IN SOA prab.K57.com. root.K57.com. ( 2026092901 604800 86400 2419200 604800 )
@ IN NS prab.K57.com.
@ IN NS tedd.K57.com.
@ IN A 10.92.3.2
prab IN A 10.92.1.2
tedd IN A 10.92.1.3

# tedd - named.conf.local
zone "K57.com" {
    type slave;
    masters { 10.92.1.2; };
    file "/etc/bind/jarkom/K57.com";
};
```
Semua client mengganti resolver menjadi prab, tedd, lalu `192.168.122.1`. Forwarder prab ke `192.168.122.1` untuk nama di luar `K57.com`.

**Langkah Menjalankan**
1. Script prab dan tedd menginstall `bind9`, menulis `named.conf.local`, file zone, `named.conf.options`, lalu `service named restart`.
2. Verifikasi dari client dengan `nslookup K57.com`, `nslookup prab.K57.com`, `nslookup tedd.K57.com`.

**Bukti / Dokumentasi**
> ![nslookup](<Script/Assets/No4_screenshot nslookup.png>)

---

### Nomor 5 - Hostname dan A Record Seluruh Node

**Permintaan Soal**
Setiap node diberi hostname sesuai glosarium, dan setiap node memiliki domain `<nama>.K57.com` yang menunjuk ke IP-nya.

**Konfigurasi yang Digunakan** ([`soal05_prab.sh`](Script/sh/soal05_prab.sh))
```bash
# setiap node
echo "alpha" > /etc/hostname
hostname alpha

# prab - tambahan A record di zone K57.com (serial 2026092902)
abbey IN A 10.92.2.2
penny IN A 10.92.3.2
alpha IN A 10.92.4.2
# ... beta, gamma, delta, epsilon, obladi, desmond, oblada, molly
```

**Bukti / Dokumentasi**
> ![Hostname](<Script/Assets/No5_hostname.png>)
>
> ![Uji coba subdomain](<Script/Assets/No5_screenshot uji coba.png>)

---

### Nomor 6 - Zone Transfer

**Permintaan Soal**
tedd menerima salinan zone terbaru dari prab dan nilai serial SOA di keduanya sama.

**Langkah Menjalankan**
1. `service named restart` di tedd, lalu cek file zone hasil transfer dengan `ls -l /etc/bind/jarkom/`.
2. Izin folder zone di tedd diatur dengan `chown -R bind:bind /etc/bind/jarkom/` dan `chmod 775`.
3. Bandingkan serial dengan `dig @10.92.1.2 K57.com SOA +short` dan `dig @10.92.1.3 K57.com SOA +short`.

**Bukti / Dokumentasi**
> ![SOA prab](<Script/Assets/No6_soa prab.png>)
>
> ![SOA tedd](<Script/Assets/No6_soa tedd.png>)

---

### Nomor 7 - A Record vault, core dan CNAME www, static

**Permintaan Soal**
`vault.K57.com` menunjuk ke IP obladi dan desmond, `core.K57.com` ke IP oblada dan molly. CNAME `www` ke penny dan `static` ke abbey.

**Konfigurasi yang Digunakan** ([`soal07_prab.sh`](Script/sh/soal07_prab.sh), serial `2026092903`)
```bash
vault IN A 10.92.5.4
vault IN A 10.92.5.5
core IN A 10.92.5.6
core IN A 10.92.5.7
www IN CNAME penny.K57.com.
static IN CNAME abbey.K57.com.
```

**Langkah Menjalankan**
1. Script prab dijalankan ulang, tedd di-restart untuk mengambil zone baru.
2. Verifikasi dari alpha dan beta dengan `nslookup www.K57.com`, `static.K57.com`, `vault.K57.com`, `core.K57.com`.

**Bukti / Dokumentasi**
> ![Cek alpha](<Script/Assets/No7_check alpha.png>)
>
> ![Cek beta](<Script/Assets/No7_check beta.png>)

---

### Nomor 8 - Reverse Zone

**Permintaan Soal**
prab mendeklarasikan reverse zone untuk segmen abbey, penny, area vault, dan area core. tedd menarik reverse zone sebagai slave, dan query reverse dijawab authoritative.

**Konfigurasi yang Digunakan** ([`soal08_prab.sh`](Script/sh/soal08_prab.sh), [`soal08_tedd.sh`](Script/sh/soal08_tedd.sh), serial `2026092904`)
```bash
# prab - reverse zone
zone "2.92.10.in-addr.arpa"  -> 2 IN PTR abbey.K57.com.
zone "3.92.10.in-addr.arpa"  -> 2 IN PTR penny.K57.com.
zone "5.92.10.in-addr.arpa"  -> 4 IN PTR obladi.K57.com.
                                5 IN PTR desmond.K57.com.
                                6 IN PTR oblada.K57.com.
                                7 IN PTR molly.K57.com.
# tedd - ketiga zone sebagai type slave dengan masters { 10.92.1.2; }
```

**Langkah Menjalankan**
1. Jalankan ulang script prab dan tedd.
2. Verifikasi dengan `host <IP> 10.92.1.2` (prab) dan `host <IP> 10.92.1.3` (tedd).

**Bukti / Dokumentasi**
> ![Verifikasi prab](<Script/Assets/No8_verifikasi prab.png>)
>
> ![Verifikasi tedd](<Script/Assets/No8_verifikasi tedd.png>)

---

### Nomor 9 - Web Statis Area Vault (Apache + autoindex)

**Permintaan Soal**
obladi dan desmond menjalankan web statis dengan Apache. Folder `/arsip/` menampilkan daftar file (directory listing).

**Konfigurasi yang Digunakan** ([`soal09_obladi-desmond.sh`](Script/sh/soal09_obladi-desmond.sh))
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

**Langkah Menjalankan**
1. Install `apache2`, buat `/var/www/vault/index.html` (berisi nama node) dan file contoh di `/var/www/vault/arsip/`.
2. `Options +Indexes` hanya untuk `/arsip`, halaman utama tetap tanpa listing.
3. `a2ensite vault`, `a2dissite 000-default`, `apache2ctl configtest`, `service apache2 restart`.
4. Script sama untuk desmond, nama node diambil dari `$(hostname)`.

**Bukti / Dokumentasi**
> ![Config vhost](<Script/Assets/No09_%2305_config vhost.png>)
>
> ![Arsip autoindex](<Script/Assets/No09_%2309_test arsip obladi 2.png>)
>
> ![Test desmond](<Script/Assets/No09_%2312_test desmond.png>)

Detail: [`Script/soal9.md`](Script/soal9.md)

---

### Nomor 10 - Web Dinamis Area Core (Nginx + PHP-FPM)

**Permintaan Soal**
oblada dan molly menjalankan aplikasi PHP lewat Nginx dengan halaman beranda dan profil. `/profil` dapat diakses tanpa akhiran `.php`.

**Konfigurasi yang Digunakan** ([`soal10_oblada-molly.sh`](Script/sh/soal10_oblada-molly.sh))
```nginx
server {
    listen 80;
    server_name core.K57.com oblada.K57.com;
    root /var/www/core;
    index index.php;

    location / {
        try_files $uri $uri/ $uri.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
```

**Langkah Menjalankan**
1. Install `nginx` dan `php8.4-fpm`, buat `index.php` dan `profil.php` (menampilkan hostname dan waktu server).
2. `try_files ... $uri.php` adalah aturan clean URL: `/profil` dilayani oleh `profil.php` tanpa mengubah URL.
3. Aktifkan site, `nginx -t`, restart.

**Bukti / Dokumentasi**
> ![Config nginx](<Script/Assets/No10_%2305_config nginx.png>)
>
> ![Test oblada](<Script/Assets/No10_%2307_test oblada.png>)
>
> ![Test molly](<Script/Assets/No10_%2313_test molly.png>)

Detail: [`Script/soal10.md`](Script/soal10.md)

---

### Nomor 11 - Reverse Proxy dan Load Balancing

**Permintaan Soal**
penny (Apache) menjadi reverse proxy ke area vault, abbey (Nginx) ke area core. Keduanya meneruskan header `Host` dan `X-Real-IP`, dan pembagian lalu lintas dibuktikan.

**Konfigurasi yang Digunakan** ([`soal11_penny.sh`](Script/sh/soal11_penny.sh), [`soal11_abbey.sh`](Script/sh/soal11_abbey.sh))
```apache
# penny - /etc/apache2/sites-available/penny.conf
<Proxy "balancer://vault">
    BalancerMember http://10.92.1.4
    BalancerMember http://10.92.1.5
    ProxySet lbmethod=byrequests
</Proxy>
ProxyPreserveHost On
RequestHeader set X-Real-IP "expr=%{REMOTE_ADDR}"
ProxyPass        / balancer://vault/
ProxyPassReverse / balancer://vault/
```
```nginx
# abbey - /etc/nginx/sites-available/abbey
upstream core {
    zone core 64k;
    server 10.92.1.6;
    server 10.92.1.7;
}
location / {
    proxy_pass http://core;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

**Langkah Menjalankan**
1. penny: aktifkan modul `proxy`, `proxy_http`, `proxy_balancer`, `lbmethod_byrequests`, `headers`. Server name `www.K57.com`.
2. abbey: Nginx dengan `upstream core`. `zone core 64k` membuat hitungan round-robin dibagi ke semua worker Nginx.
3. Pembagian beban dibuktikan dengan request berulang (bergantian obladi - desmond dan oblada - molly), header dibuktikan dengan `tcpdump -A` di backend.

**Bukti / Dokumentasi**
> ![Balancing penny](<Script/Assets/No11_%2306_test balancing penny.png>)
>
> ![Header penny](<Script/Assets/No11_%2314_tcpdump header penny.png>)
>
> ![Balancing abbey](<Script/Assets/No11_%2321_test balancing abbey.png>)
>
> ![Header abbey](<Script/Assets/No11_%2322_tcpdump header abbey.png>)
>
> ![Test hostname www](<Script/Assets/No11_%2328_test hostname www.png>)

Detail: [`Script/soal11.md`](Script/soal11.md)

---

### Nomor 12 - Basic Authentication /admin di penny

**Permintaan Soal**
Path `/admin` di penny menolak pengunjung tanpa kredensial dan hanya mengizinkan user `prabs`.

**Konfigurasi yang Digunakan**
```bash
apt-get install -y apache2-utils
htpasswd -bc /etc/apache2/.htpasswd prabs <password>
a2enmod auth_basic
```
```apache
<Directory /var/www/html/admin>
    AuthType Basic
    AuthName "Restricted Admin Area"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Directory>
```

**Langkah Menjalankan**
1. Buat `/var/www/html/admin/index.html`, atur kepemilikan ke `www-data`.
2. Uji tanpa kredensial (`401 Unauthorized`) dan dengan `curl -u prabs:<password>` (`200 OK`).

**Bukti / Dokumentasi**
> ![Tanpa kredensial](<Script/Assets/No12_test tanpa kredensial.png>)
>
> ![Dengan kredensial](<Script/Assets/No12_with kredensial.png>)

Detail: [`Script/soal12.md`](Script/soal12.md)

---

### Nomor 13 - Redirect ke Nama Kanonik

**Permintaan Soal**
Akses ke IP dan domain penny diarahkan permanen (301) ke `www.K57.com`. Akses ke IP dan domain abbey diarahkan sementara (302) ke `static.K57.com`.

**Konfigurasi yang Digunakan**
```apache
# penny - 000-default.conf
<VirtualHost *:80>
    ServerName penny.K57.com
    ServerAlias 10.92.3.2
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/admin [NC]
    RewriteRule ^(.*)$ http://www.K57.com/$1 [R=301,L]
    # ... blok <Directory> /admin dari soal 12
</VirtualHost>

# abbey - 000-default.conf
<VirtualHost *:80>
    ServerName abbey.K57.com
    ServerAlias 10.92.2.2
    Redirect 302 / http://static.K57.com/
</VirtualHost>
```

**Langkah Menjalankan**
1. penny: `a2enmod rewrite`. Folder `/admin` dikecualikan dari redirect supaya basic auth soal 12 tetap dapat diakses.
2. abbey: virtual host khusus nama `abbey.K57.com` dan IP abbey yang hanya berisi redirect 302.
3. Verifikasi dengan `curl -I` ke IP dan domain masing-masing gerbang.

**Bukti / Dokumentasi**
> ![Test penny](<Script/Assets/No13_test penny di alpha.png>)
>
> ![Test abbey](<Script/Assets/No13_test abbey di alpha.png>)

Detail: [`Script/soal13.md`](Script/soal13.md)

---

### Nomor 14 - IP Asli Client di Access Log Backend

**Permintaan Soal**
Access log di setiap web server area vault dan area core mencatat IP asli client, bukan IP penny atau abbey.

**Konfigurasi yang Digunakan** ([`soal14_obladi-desmond.sh`](Script/sh/soal14_obladi-desmond.sh), [`soal14_oblada-molly.sh`](Script/sh/soal14_oblada-molly.sh))
```apache
# obladi, desmond (a2enmod remoteip)
RemoteIPHeader X-Real-IP
RemoteIPInternalProxy 10.92.3.2
LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" realip
CustomLog ${APACHE_LOG_DIR}/vault_access.log realip
```
```nginx
# oblada, molly
set_real_ip_from 10.92.2.2;
real_ip_header X-Real-IP;
```

**Langkah Menjalankan**
1. Header `X-Real-IP` hanya dipercaya jika request datang dari gerbangnya sendiri (penny `10.92.3.2` untuk vault, abbey `10.92.2.2` untuk core), sehingga client tidak dapat memalsukan IP.
2. Bandingkan log sebelum dan sesudah: request dari alpha tercatat `10.92.4.2`.

**Bukti / Dokumentasi**
> ![Log obladi sebelum](<Script/Assets/No14_%2304_log obladi sebelum.png>)
>
> ![Log obladi sesudah](<Script/Assets/No14_%2306_log obladi sesudah.png>)
>
> ![Log oblada sesudah](<Script/Assets/No14_%2317_log oblada sesudah.png>)
>
> ![Log molly sesudah](<Script/Assets/No14_%2321_log molly sesudah.png>)

Detail: [`Script/soal14.md`](Script/soal14.md)

---

### Nomor 15 - Path Khusus /orion dan /eternal

**Permintaan Soal**
abbey menyajikan `/orion` dari `/var/www/orion` secara statis. penny menyajikan `/eternal` dari `/var/www/eternal` dan menjalankan file PHP.

**Konfigurasi yang Digunakan** ([`soal15_abbey.sh`](Script/sh/soal15_abbey.sh), [`soal15_penny.sh`](Script/sh/soal15_penny.sh))
```nginx
# abbey - di atas location /
location /orion {
    alias /var/www/orion;
    index index.html;
}
```
```apache
# penny - /etc/apache2/eternal.conf, di-Include sebelum ProxyPass /
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

**Langkah Menjalankan**
1. abbey: tanpa `fastcgi_pass`, sehingga file `.php` di `/orion` dikirim sebagai teks biasa (bukti statis).
2. penny: install `php8.4-fpm`, `a2enmod proxy_fcgi`. `ProxyPass /eternal !` mengecualikan path ini dari load balancer, dan `Include` diletakkan sebelum `ProxyPass /`.
3. Halaman eternal menampilkan waktu server, dua request berjeda menghasilkan waktu berbeda (bukti dinamis).

**Bukti / Dokumentasi**
> ![Test orion](<Script/Assets/No15_%2306_test orion abbey.png>)
>
> ![Test eternal](<Script/Assets/No15_%2315_test eternal penny.png>)
>
> ![Eternal dinamis](<Script/Assets/No15_%2316_test eternal dinamis.png>)

Detail: [`Script/soal15.md`](Script/soal15.md)

---

### Nomor 16 - Stress Test ApacheBench

**Permintaan Soal**
Dari salah satu client, jalankan ApacheBench 250 request dengan konkurensi 10 ke `www.K57.com` dan `static.K57.com`.

**Konfigurasi yang Digunakan** ([`soal16_alpha.sh`](Script/sh/soal16_alpha.sh))
```bash
apt-get install -y apache2-utils
ab -n 250 -c 10 http://www.K57.com/
ab -n 250 -c 10 http://static.K57.com/
```

**Hasil**

| | `www.K57.com` | `static.K57.com` |
|---|---|---|
| Complete requests | 250 | 250 |
| Failed (Connect / Receive / Exceptions) | 0 / 0 / 0 | 0 / 0 / 0 |
| Failed (Length) | 125 | 125 |
| Requests per second | 1517.34 | 1280.25 |
| Time per request | 6.590 ms | 7.811 ms |

`Failed (Length) 125` bukan kegagalan. ApacheBench menandai response yang panjangnya berbeda dari response pertama, dan halaman obladi / desmond (serta oblada / molly) berbeda satu huruf. Tepat setengah dari 250 request membuktikan pembagian round-robin. Access log masing-masing backend mencatat 125 request ApacheBench.

**Bukti / Dokumentasi**
> ![Benchmark www](<Script/Assets/No16_%2303_benchmark www.png>)
>
> ![Benchmark static](<Script/Assets/No16_%2304_benchmark static.png>)
>
> ![Jumlah request vault](<Script/Assets/No16_%2305_jumlah request vault.png>)

Detail: [`Script/soal16.md`](Script/soal16.md)

---

### Nomor 17 - TXT Record Client

**Permintaan Soal**
Query TXT ke `alpha.K57.com`, `beta.K57.com`, `gamma.K57.com`, `delta.K57.com`, `epsilon.K57.com` mengembalikan nama hostname masing-masing.

**Konfigurasi yang Digunakan** ([`soal17_prab.sh`](Script/sh/soal17_prab.sh))
```diff
- echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026092904 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
+ echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093001 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
  echo 'static IN CNAME abbey.K57.com.' >> /etc/bind/jarkom/K57.com
+ echo 'alpha IN TXT "alpha"' >> /etc/bind/jarkom/K57.com
+ echo 'beta IN TXT "beta"' >> /etc/bind/jarkom/K57.com
+ echo 'gamma IN TXT "gamma"' >> /etc/bind/jarkom/K57.com
+ echo 'delta IN TXT "delta"' >> /etc/bind/jarkom/K57.com
+ echo 'epsilon IN TXT "epsilon"' >> /etc/bind/jarkom/K57.com
```

**Langkah Menjalankan**
1. Perubahan dilakukan di `/root/script.sh` prab (bukan langsung di file zone), karena zone dibuat ulang setiap script dijalankan.
2. Serial dinaikkan agar tedd ikut mengambil zone baru.
3. Verifikasi `dig TXT alpha.K57.com` (sebelum: `ANSWER: 0`, sesudah: `"alpha"`) dan query langsung ke tedd.

**Bukti / Dokumentasi**
> ![Sebelum](<Script/Assets/No17_%2301_dig txt sebelum.png>)
>
> ![Hasil TXT](<Script/Assets/No17_%2307_test serial dan txt alpha.png>)

Detail: [`Script/soal17.md`](Script/soal17.md)

---

### Nomor 18 - TTL dan Cache DNS

**Permintaan Soal**
A record `abbey.K57.com` diubah ke IP fiktif dengan TTL 15 detik, serial dinaikkan dan tedd tersinkron. Tiga fase dibuktikan: sebelum perubahan (IP lama), dalam 15 detik setelah perubahan (masih IP lama karena cache), dan setelah TTL habis (IP fiktif).

**Konfigurasi yang Digunakan** ([`soal18_beta.sh`](Script/sh/soal18_beta.sh), [`soal18_prab.sh`](Script/sh/soal18_prab.sh))
```bash
# beta - resolver cache (bind9) yang meneruskan ke prab
options {
    directory "/var/cache/bind";
    forwarders { 10.92.1.2; };
    forward only;
    dnssec-validation no;
    prefetch 0;
    allow-query { any; };
};
```
```diff
# prab - file zone
- abbey IN A 10.92.2.2            # serial 2026093002
+ abbey 15 IN A 10.92.2.2         # serial 2026093003, TTL 15 dengan IP asli
+ abbey 15 IN A 192.0.2.18        # serial 2026093004, IP fiktif (blok dokumentasi RFC 5737)
```

**Langkah Menjalankan**
1. prab adalah server authoritative sehingga selalu menjawab dari zone, karena itu cache diamati lewat resolver di beta (`dig @127.0.0.1`).
2. TTL diubah ke 15 lebih dulu dengan IP asli, kemudian zone fiktif diterapkan dengan `rndc reload` dalam jeda 15 detik.
3. Setelah percobaan, zone dikembalikan normal lewat `script.sh` prab dengan serial `2026093005` (lebih besar dari serial fiktif agar tedd ikut kembali).

**Hasil**

| Fase | Waktu (UTC) | Lewat cache beta | TTL | Langsung ke prab / tedd |
|---|---|---|---|---|
| 1. sebelum perubahan | 15:16:06 | `10.92.2.2` | 15 | `10.92.2.2` |
| 2. dalam 15 detik | 15:16:09 | `10.92.2.2` | 12 | `192.0.2.18` |
| 3. setelah TTL habis | 15:17:35 | `192.0.2.18` | 15 | `192.0.2.18` |

**Bukti / Dokumentasi**
> ![Fase 1 dan 2](<Script/Assets/No18_%2315_fase 1 dan fase 2.png>)
>
> ![Fase 2 sumber prab](<Script/Assets/No18_%2316_fase 2 sumber prab.png>)
>
> ![Fase 3](<Script/Assets/No18_%2317_fase 3.png>)
>
> ![Revert](<Script/Assets/No18_%2321_cek revert beta.png>)

Detail: [`Script/soal18.md`](Script/soal18.md)

---

### Nomor 19 - CNAME ke Domain Eksternal

**Permintaan Soal**
`outbound.K57.com` menjadi CNAME ke `http.badssl.com`, dan `curl http://outbound.K57.com` menampilkan isi halaman `http.badssl.com`.

**Konfigurasi yang Digunakan** ([`soal19_prab.sh`](Script/sh/soal19_prab.sh), serial `2026093002`)
```bash
echo 'outbound IN CNAME http.badssl.com.' >> /etc/bind/jarkom/K57.com
```

**Langkah Menjalankan**
1. Titik di akhir `http.badssl.com.` menandakan nama absolut.
2. `dig outbound.K57.com` menghasilkan CNAME ke `http.badssl.com.` beserta A record badssl (`104.154.89.105`) yang dicari prab lewat forwarder.
3. Server badssl memilih website berdasarkan header `Host`, sehingga curl dilakukan dengan `curl -H "Host: http.badssl.com" http://outbound.K57.com/`. Koneksi tetap memakai CNAME kita, dan hasilnya sama dengan halaman `http.badssl.com`.

**Bukti / Dokumentasi**
> ![Dig outbound](<Script/Assets/No19_%2307_test serial dan dig outbound.png>)
>
> ![Curl outbound](<Script/Assets/No19_%2308_curl outbound.png>)

Detail: [`Script/soal19.md`](Script/soal19.md)

---

### Nomor 20 - Persistensi Service Setelah Restart

**Permintaan Soal**
Seluruh service dan konfigurasi dari soal sebelumnya tetap berjalan dan aktif otomatis saat node di-restart (konfigurasi soal 18 diabaikan).

**Konfigurasi yang Digunakan** ([`soal20_obladi-desmond.sh`](Script/sh/soal20_obladi-desmond.sh), [`soal20_oblada-molly.sh`](Script/sh/soal20_oblada-molly.sh))

Node Docker di GNS3 tidak memakai systemd, sehingga service dinyalakan dari perintah yang berjalan saat node menyala:

| Node | Mekanisme | Service |
|---|---|---|
| rootkid | `up bash /root/script.sh` | `ip_forward` + `iptables` NAT |
| prab, tedd | `up bash /root/script.sh` | install dan konfigurasi bind9, `service named restart` |
| obladi, desmond | `up bash /root/script.sh` | `service apache2 start` |
| oblada, molly | `up bash /root/script.sh` | `service php8.4-fpm start`, `service nginx start` |
| penny, abbey | `/etc/bash.bashrc` | `service apache2 start` |
| client | `up bash /root/script.sh` | resolv.conf |

```bash
# oblada, molly - /root/script.sh
#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "nameserver 10.92.1.2" > /etc/resolv.conf
echo "nameserver 10.92.1.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf
service php8.4-fpm start
service nginx start
```
Baris `PATH` diperlukan karena saat boot script dijalankan dengan PATH milik GNS3 yang mendahulukan busybox. Perintah `ps` versi busybox salah membaca pid file sisa sebelum restart, sehingga `service ... start` mengira service sudah berjalan. Dengan PATH normal, service menyala dengan benar.

**Bukti / Dokumentasi**
> ![Script desmond](<Script/Assets/No20_%2303_script autostart desmond.png>)
>
> ![Script oblada](<Script/Assets/No20_%2304_script autostart oblada.png>)

Detail: [`Script/soal20.md`](Script/soal20.md)

---

## IV. Rekap Script

Seluruh script tersedia di [`Script/sh/`](Script/sh/) dan disimpan di `/root` pada node terkait.

| Script | Node | Soal |
|---|---|---|
| `soal02_rootkid.sh` | rootkid | NAT dan IP forwarding |
| `soal03_client.sh`, `soal04_client.sh` | semua client | resolver |
| `soal04_prab.sh`, `soal05_prab.sh`, `soal07_prab.sh`, `soal08_prab.sh` | prab | perkembangan zone DNS |
| `soal04_tedd.sh`, `soal08_tedd.sh` | tedd | slave forward dan reverse |
| `soal09_obladi-desmond.sh` | obladi, desmond | web statis vault |
| `soal10_oblada-molly.sh` | oblada, molly | web dinamis core |
| `soal11_penny.sh`, `soal11_abbey.sh` | penny, abbey | reverse proxy dan load balancer |
| `soal14_obladi-desmond.sh`, `soal14_oblada-molly.sh` | backend | IP asli di access log |
| `soal15_penny.sh`, `soal15_abbey.sh` | penny, abbey | `/eternal` dan `/orion` |
| `soal16_alpha.sh` | alpha | ApacheBench |
| `soal17_prab.sh`, `soal19_prab.sh`, `soal18_prab.sh` | prab | TXT, CNAME outbound, zone akhir |
| `soal18_beta.sh` | beta | resolver cache percobaan TTL |
| `soal20_obladi-desmond.sh`, `soal20_oblada-molly.sh` | backend | autostart saat boot |

Riwayat serial zone `K57.com`:

| Serial | Soal | Perubahan |
|---|---|---|
| `2026092901` | 4 | zone awal (SOA, NS, prab, tedd) |
| `2026092902` | 5 | A record semua node |
| `2026092903` | 7 | vault, core, CNAME www dan static |
| `2026092904` | 8 | reverse zone |
| `2026093001` | 17 | TXT record client |
| `2026093002` | 19 | CNAME outbound |
| `2026093003` - `2026093004` | 18 | TTL 15 dan IP fiktif (sementara) |
| `2026093005` | 18 | zone kembali normal |

---

## V. Kesimpulan

- **DNS** dibangun bertahap di satu sumber, yaitu `/root/script.sh` prab yang menulis ulang seluruh zone setiap dijalankan. Setiap perubahan disertai kenaikan serial SOA, karena tedd hanya mengambil zone baru jika serial master lebih besar dari miliknya.
- **Gerbang** memisahkan peran dengan jelas: penny (Apache) melayani `www.K57.com` dan membagi beban ke area vault, abbey (Nginx) melayani `static.K57.com` dan membagi beban ke area core. Header `Host` dan `X-Real-IP` diteruskan sehingga backend mengetahui nama dan IP asli pengunjung.
- **Cache DNS** hanya terjadi pada resolver rekursif, bukan pada server authoritative. Karena itu percobaan TTL memerlukan resolver di sisi client, dan TTL harus diturunkan sebelum IP diganti.
- **CNAME** hanya bekerja di level DNS. Website yang ditampilkan ditentukan oleh server tujuan dari header `Host` di level HTTP.
- **Persistensi** pada node Docker tanpa systemd bergantung pada perintah yang berjalan saat boot, dan lingkungan saat boot (PATH) dapat berbeda dari shell interaktif.
