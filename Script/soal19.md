## Soal 19 - CNAME ke domain eksternal (outbound.K57.com ke http.badssl.com)
   dijalankan di **prab** (DNS master), otomatis tersinkron ke **tedd** (slave), testing dari **beta**

`outbound.K57.com` dibuat sebagai CNAME ke `http.badssl.com`, lalu `curl http://outbound.K57.com` harus menampilkan isi halaman `http.badssl.com`

### Sebelum

1. cek dulu cara server badssl menangani header `Host` (dari beta)
```bash
curl http://http.badssl.com/
curl -H "Host: outbound.K57.com" http://http.badssl.com/
```
- request pertama : halaman merah `http.badssl.com`
- request kedua : ke IP yang sama, tetapi dengan `Host: outbound.K57.com`, hasilnya halaman default **"Welcome to nginx!"**
- server badssl memakai virtual host, satu IP melayani banyak website, website dipilih dari header `Host`. Nama `outbound.K57.com` tidak dikenal oleh server badssl, jadi yang tampil halaman default
- inilah yang nanti terjadi pada `curl http://outbound.K57.com` biasa, karena curl mengirim `Host` sesuai nama yang diketik

![alt text](<Assets/No19_%2301_cek host header badssl.png>)

2. `outbound.K57.com` belum ada
```bash
curl -H "Host: http.badssl.com" http://outbound.K57.com/
dig outbound.K57.com
```
- curl : `Could not resolve host`, nama belum bisa di-resolve
- dig : `status: NXDOMAIN`, nama tidak ada di zone (serial masih `2026093001`)

![alt text](<Assets/No19_%2302_outbound sebelum.png>)

### Konfigurasi di prab

zone `K57.com` dibuat ulang oleh `/root/script.sh`, jadi perubahan dilakukan di `script.sh` (sama seperti soal 17)

3. naikkan serial zone forward (baris 48) dari `2026093001` menjadi `2026093002`
```bash
nano /root/script.sh
```
```bash
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
```
sebelum:
![alt text](<Assets/No19_%2303_serial lama di script prab.png>)

sesudah:
![alt text](<Assets/No19_%2304_ganti serial prab.png>)

4. tambahkan CNAME setelah TXT record soal 17 (baris 76)
```bash
echo 'outbound IN CNAME http.badssl.com.' >> /etc/bind/jarkom/K57.com
```
- titik di akhir `http.badssl.com.` wajib, artinya nama absolut. Tanpa titik, BIND menambahkan nama zone menjadi `http.badssl.com.K57.com` yang tidak ada
- format sama seperti CNAME `www` dan `static`

![alt text](<Assets/No19_%2305_tambah cname outbound prab.png>)

#### Perubahan `/root/script.sh` (bagian `# 4. Forward Zone File K57.com`)

sebelum (hasil soal 17):
```bash
# 4. Forward Zone File K57.com
echo '$TTL 604800' > /etc/bind/jarkom/K57.com
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093001 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
# ... NS, A record, CNAME www dan static, TXT alpha - delta tidak berubah (baris 49 - 74)
echo 'epsilon IN TXT "epsilon"' >> /etc/bind/jarkom/K57.com
```
![alt text](<Assets/No17_%2305_tambah record txt prab.png>)

sesudah:
```bash
# 4. Forward Zone File K57.com
echo '$TTL 604800' > /etc/bind/jarkom/K57.com
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
# ... NS, A record, CNAME www dan static, TXT alpha - delta tidak berubah (baris 49 - 74)
echo 'epsilon IN TXT "epsilon"' >> /etc/bind/jarkom/K57.com
echo 'outbound IN CNAME http.badssl.com.' >> /etc/bind/jarkom/K57.com
```
(screenshot sesudah ada di langkah 4)

ringkasan perubahan (`-` baris lama, `+` baris baru):
```diff
- echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093001 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
+ echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
  echo 'epsilon IN TXT "epsilon"' >> /etc/bind/jarkom/K57.com
+ echo 'outbound IN CNAME http.badssl.com.' >> /etc/bind/jarkom/K57.com
```
bagian lain `script.sh` tidak berubah

5. cek perubahan, jalankan script, dan cek file zone
```bash
grep -n "SOA\|CNAME" /root/script.sh
bash /root/script.sh
named-checkzone K57.com /etc/bind/jarkom/K57.com
```
- baris 48 serial `2026093002`, 3 CNAME (`www`, `static`, `outbound`), SOA zone reverse tetap
- `loaded serial 2026093002` dan `OK`

![alt text](<Assets/No19_%2306_jalankan script dan checkzone prab.png>)

### Testing dari beta

6. cek serial master dan slave, lalu resolve `outbound.K57.com`
```bash
dig @10.92.1.2 SOA K57.com +short
dig @10.92.1.3 SOA K57.com +short
dig outbound.K57.com
```
- prab dan tedd sama-sama `2026093002`, tedd sudah sinkron
- `status: NOERROR`, `ANSWER: 2`
- `outbound.K57.com. 604800 IN CNAME http.badssl.com.` : CNAME dari zone kita
- `http.badssl.com. 299 IN A 104.154.89.105` : IP asli badssl, dicari oleh prab lewat forwarder (TTL 299 berarti jawaban ini diambil dari cache prab)

![alt text](<Assets/No19_%2307_test serial dan dig outbound.png>)

7. curl ke `outbound.K57.com`
```bash
curl http://outbound.K57.com/
curl -H "Host: http.badssl.com" http://outbound.K57.com/
```
- tanpa `-H` : **"Welcome to nginx!"**. Koneksi sudah sampai ke server badssl (CNAME berhasil), tetapi header `Host: outbound.K57.com` tidak dikenal server badssl
- dengan `-H "Host: http.badssl.com"` : curl tetap resolve `outbound.K57.com` lewat CNAME kita, hanya header `Host` yang disesuaikan, hasilnya **sama persis** dengan halaman `http.badssl.com` di langkah 1

![alt text](<Assets/No19_%2308_curl outbound.png>)

### Catatan

- CNAME hanya bekerja di level DNS (menentukan IP tujuan). Website yang ditampilkan ditentukan oleh server tujuan dari header `Host` di level HTTP
- membuat `outbound` sebagai A record ke proxy sendiri yang mengganti header `Host` akan membuat curl biasa langsung berhasil, tetapi itu bukan CNAME lagi, jadi tidak sesuai soal
