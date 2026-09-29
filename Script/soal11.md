## Soal 11 - Reverse proxy + load balancing (penny ke vault, abbey ke core)
   **penny** (Apache) meneruskan ke **obladi** & **desmond**, **abbey** (Nginx) meneruskan ke **oblada** & **molly**

```
client --> penny (Apache) --+--> obladi  10.92.1.4   (vault)
           www.K57.com      +--> desmond 10.92.1.5

client --> abbey (Nginx)  --+--> oblada  10.92.1.6   (core)
           static.K57.com   +--> molly   10.92.1.7
```
backend ditulis pakai IP, jadi proxy tetap jalan walaupun DNS bermasalah

### Penny (Apache)

1. install apache dan aktifkan modul proxy
```bash
apt-get update
apt-get install -y apache2
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers
service apache2 start
apache2ctl -M | grep -E "proxy|lbmethod|headers"
```
- `proxy`, `proxy_http` : fitur reverse proxy HTTP
- `proxy_balancer`, `lbmethod_byrequests` : membagi request ke beberapa backend secara bergantian (round-robin)
- `headers` : untuk menambahkan header `X-Real-IP`

![alt text](<Assets/No11_enable modul proxy.png>)

2. config virtualhost di `/etc/apache2/sites-available/penny.conf`
```apache
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
```
- `balancer://vault` : grup backend obladi dan desmond
- `ProxyPreserveHost On` : forwarding header **Host** (backend menerima `www.K57.com`, bukan IP)
- `RequestHeader set X-Real-IP "expr=%{REMOTE_ADDR}"` : forwarding header **X-Real-IP** berisi IP client asli
- `ProxyPassReverse` : redirect dari backend (misal `/arsip` ke `/arsip/`) diubah ke nama penny, bukan IP backend

![alt text](<Assets/No11_cek config penny.png>)

3. aktifkan site
```bash
a2ensite penny
a2dissite 000-default
apache2ctl configtest
service apache2 restart
```
![alt text](<Assets/No11_enable site penny.png>)

4. testing dari abbey (sebagai client)
```bash
curl -H "Host: www.K57.com" http://10.92.3.2/
curl -H "Host: www.K57.com" http://10.92.3.2/
curl -H "Host: www.K57.com" http://10.92.3.2/
curl -H "Host: www.K57.com" http://10.92.3.2/
curl -H "Host: www.K57.com" http://10.92.3.2/arsip/
curl -I -H "Host: www.K57.com" http://10.92.3.2/arsip
```
request bergantian obladi - desmond (load balancing berhasil), `/arsip/` tetap bisa dibuka lewat proxy, redirect `/arsip` mengarah ke `www.k57.com`
![alt text](<Assets/No11_test balancing penny.png>)

bukti header sampai di backend, pakai `tcpdump` di obladi (request dikirim dari abbey)
```bash
tcpdump -A -i eth0 -c 10 port 80
```
- paket datang dari `10.92.3.2` (penny)
- `Host: www.K57.com`
- `X-Real-IP: 10.92.2.2` (IP abbey, client asli)

![alt text](<Assets/No11_tcpdump header penny.png>)

### Abbey (Nginx)

5. install nginx (abbey hanya proxy, tidak perlu php)
```bash
apt-get update
apt-get install -y nginx
service nginx start
```
![alt text](<Assets/No11_cek nginx abbey.png>)

6. config di `/etc/nginx/sites-available/abbey`
```nginx
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
```
- `upstream core` : grup backend oblada dan molly (default round-robin)
- `zone core 64k` : state round-robin disimpan di shared memory, supaya semua worker nginx bergantian dengan benar
- `proxy_set_header Host $host` : forwarding header **Host**
- `proxy_set_header X-Real-IP $remote_addr` : forwarding header **X-Real-IP**

![alt text](<Assets/No11_config abbey.png>)

7. aktifkan site
```bash
ln -sf /etc/nginx/sites-available/abbey /etc/nginx/sites-enabled/abbey
rm -f /etc/nginx/sites-enabled/default
nginx -t
service nginx restart
```
![alt text](<Assets/No11_restart nginx abbey.png>)

8. testing dari penny (sebagai client)
```bash
curl -H "Host: static.K57.com" http://10.92.2.2/
curl -H "Host: static.K57.com" http://10.92.2.2/
curl -H "Host: static.K57.com" http://10.92.2.2/
curl -H "Host: static.K57.com" http://10.92.2.2/
```
request bergantian oblada - molly
![alt text](<Assets/No11_test balancing abbey.png>)

bukti header, `tcpdump` di oblada (request dikirim dari penny)
- paket datang dari abbey (`10.92.2.2`)
- `Host: static.k57.com`
- `X-Real-IP: 10.92.3.2` (IP penny, client asli)

![alt text](<Assets/No11_tcpdump header abbey.png>)

### Script

9. script `/root/soal11.sh` di penny
```bash
cat > /root/soal11.sh <<'SCRIPT'
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
SCRIPT
```

script `/root/soal11.sh` di abbey
```bash
cat > /root/soal11.sh <<'SCRIPT'
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
SCRIPT
```
kedua heredoc pakai tanda kutip (`<<'EOF'`), jadi variabel apache / nginx (`${APACHE_LOG_DIR}`, `$host`, `$remote_addr`) tidak diganti oleh shell

### Testing lewat hostname

10. setelah DNS (soal 7) jadi, akses langsung pakai nama
```bash
curl http://www.K57.com/
curl http://static.K57.com/
```
`www` (CNAME ke penny) dan `static` (CNAME ke abbey) tetap membagi request ke dua backend

dari abbey ke `www.K57.com`:
![alt text](<Assets/No11_test hostname www.png>)

dari penny ke `static.K57.com`:
![alt text](<Assets/No11_test hostname static.png>)

### Catatan perbaikan

- awalnya penny memakai `RequestHeader set X-Real-IP "%{REMOTE_ADDR}s"`, hasilnya `X-Real-IP: (null)`, karena akhiran `s` di mod_headers berarti variabel SSL (mod_ssl). Diganti menjadi `"expr=%{REMOTE_ADDR}"`

![alt text](<Assets/No11_tcpdump x-real-ip null.png>)

- awalnya abbey tidak bergantian (oblada terus), karena tiap worker nginx punya hitungan round-robin sendiri. Ditambahkan `zone core 64k;` di upstream supaya hitungannya dibagi ke semua worker

![alt text](<Assets/No11_test abbey tidak rata.png>)
