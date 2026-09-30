## Soal 18 - TTL dan cache DNS (A record abbey diubah ke IP fiktif)
   dijalankan di **prab** (DNS master) dan **beta** (client + resolver cache), **tedd** (slave) ikut tersinkron

| Fase | Yang diharapkan |
|------|-----------------|
| 1. sebelum perubahan | IP lama `10.92.2.2` |
| 2. perubahan baru terjadi, masih dalam 15 detik | masih IP lama, dari cache |
| 3. setelah TTL 15 detik habis | IP fiktif baru `192.0.2.18` |

- IP fiktif `192.0.2.18` diambil dari blok `192.0.2.0/24` (RFC 5737), blok khusus dokumentasi. Format IP valid, tetapi dijamin bukan milik host mana pun
- perubahan ini sementara, setelah percobaan zone dikembalikan normal (soal 20 juga meminta konfigurasi soal 18 diabaikan)

### Kenapa perlu resolver cache

client biasa bertanya langsung ke prab. prab adalah server **authoritative** untuk `K57.com`, jadi prab selalu menjawab dari isi zone saat itu, tidak pernah dari cache. Begitu zone diubah, prab langsung menjawab IP baru, sehingga fase 2 (masih IP lama karena cache) tidak akan pernah terlihat

karena itu di beta dipasang **resolver cache** (bind9 yang meneruskan semua pertanyaan ke prab dan menyimpan jawabannya selama TTL). Testing dilakukan lewat resolver ini (`dig @127.0.0.1`)

```
beta (dig @127.0.0.1) --> resolver cache di beta --> prab (authoritative) --> tedd (slave)
```

### A. Resolver cache di beta

1. install bind9 dan buat config resolver
```bash
apt-get update
apt-get install -y bind9

cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    forwarders { 10.92.1.2; };
    forward only;
    dnssec-validation no;
    prefetch 0;
    allow-query { any; };
};
EOF
service named restart
```
- `forwarders { 10.92.1.2; }` + `forward only` : semua pertanyaan diteruskan ke prab, jawabannya disimpan di cache beta selama TTL
- `dnssec-validation no` : `K57.com` bukan domain asli, validasi DNSSEC akan menolaknya
- `prefetch 0` : BIND biasanya memperbarui record otomatis sesaat sebelum TTL habis, fitur ini dimatikan supaya fase 2 tidak terganggu

2. cek config dan resolver
```bash
cat /etc/bind/named.conf.options
dig @127.0.0.1 prab.K57.com +short
```
`10.92.1.2`, resolver di beta sudah bisa menjawab lewat prab

![alt text](<Assets/No18_%2303_config resolver cache beta.png>)

### B. TTL 15 detik di abbey (prab)

perubahan soal 18 dilakukan langsung di file zone `/etc/bind/jarkom/K57.com`, bukan di `script.sh`, karena sifatnya sementara. Di tahap D, `script.sh` dijalankan lagi untuk mengembalikan zone normal

3. TTL 15 dengan IP asli, serial `2026093002` menjadi `2026093003`
```bash
nano /etc/bind/jarkom/K57.com
```
perubahan file zone `/etc/bind/jarkom/K57.com`

sebelum (dibuat oleh `script.sh` soal 19):
```
$TTL 604800
@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )
; ... NS dan A record prab, tedd tidak berubah
abbey IN A 10.92.2.2
; ... record lain tidak berubah
```

sesudah:
```
$TTL 604800
@ IN SOA prab.K57.com. root.K57.com. ( 2026093003 604800 86400 2419200 604800 )
; ... NS dan A record prab, tedd tidak berubah
abbey 15 IN A 10.92.2.2
; ... record lain tidak berubah
```

ringkasan perubahan (`-` baris lama, `+` baris baru):
```diff
- @ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )
+ @ IN SOA prab.K57.com. root.K57.com. ( 2026093003 604800 86400 2419200 604800 )
- abbey IN A 10.92.2.2
+ abbey 15 IN A 10.92.2.2
```
- angka `15` di antara nama dan `IN` adalah TTL khusus record ini, record lain tetap memakai `$TTL 604800`
- TTL harus diubah ke 15 **sebelum** IP diganti. Cache menyimpan record sesuai TTL saat record itu diambil. Kalau IP lama tersimpan dengan TTL 604800, cache akan memakai IP lama selama 7 hari

sebelum:
![alt text](<Assets/No18_%2304_zone prab sebelum.png>)

sesudah:
![alt text](<Assets/No18_%2305_ttl 15 abbey prab.png>)

```bash
named-checkzone K57.com /etc/bind/jarkom/K57.com
service named restart
```
![alt text](<Assets/No18_%2306_checkzone dan restart prab.png>)

4. siapkan zone dengan IP fiktif (belum dipakai), serial `2026093004`
```bash
cp /etc/bind/jarkom/K57.com /root/K57-fiktif
nano /root/K57-fiktif
```
perbedaan `/root/K57-fiktif` dengan zone TTL 15 yang sedang aktif (`-` baris lama, `+` baris baru):
```diff
- @ IN SOA prab.K57.com. root.K57.com. ( 2026093003 604800 86400 2419200 604800 )
+ @ IN SOA prab.K57.com. root.K57.com. ( 2026093004 604800 86400 2419200 604800 )
- abbey 15 IN A 10.92.2.2
+ abbey 15 IN A 192.0.2.18
```
di fase 2 perubahan harus terjadi dalam beberapa detik, jadi file disiapkan dulu supaya perubahan cukup dengan satu perintah `cp`

![alt text](<Assets/No18_%2308_zone fiktif prab.png>)

```bash
named-checkzone K57.com /root/K57-fiktif
```
`named-checkzone` bisa mengecek file mana pun, file fiktif sudah valid sebelum dipakai

![alt text](<Assets/No18_%2310_checkzone fiktif prab.png>)

5. cek dari beta, langsung ke prab dan tedd
```bash
dig @10.92.1.2 abbey.K57.com
dig @10.92.1.3 abbey.K57.com
```
keduanya `abbey.K57.com. 15 IN A 10.92.2.2`, TTL 15 sudah aktif dan tedd sudah sinkron serial `2026093003`

![alt text](<Assets/No18_%2311_ttl 15 di prab dan tedd.png>)

### C. Tiga fase

beta dan prab dibuka berdampingan. Fase 1, perubahan, dan fase 2 harus terjadi dalam 15 detik

6. persiapan
```bash
# prab : backup zone TTL 15, untuk mengulang percobaan kalau waktunya terlewat
cp /etc/bind/jarkom/K57.com /root/K57-ttl15

# beta : kosongkan cache
service named restart

# prab : ketik perintah ini tanpa Enter
cp /root/K57-fiktif /etc/bind/jarkom/K57.com && rndc reload
```
`rndc reload` membuat named yang sedang berjalan membaca ulang file zone dalam waktu kurang dari 1 detik, jauh lebih cepat dari `service named restart`

7. fase 1 (beta), perubahan (prab), fase 2 (beta)
```bash
# beta : fase 1
dig @127.0.0.1 abbey.K57.com

# prab : Enter pada perintah yang sudah disiapkan

# beta : fase 2
dig @127.0.0.1 abbey.K57.com
dig @10.92.1.2 abbey.K57.com +short
```
- fase 1 (`15:16:06`) : `10.92.2.2`, TTL `15`, baru diambil dari prab, hitungan cache 15 detik dimulai
- prab : `server reload successful`, zone sekarang IP fiktif serial `2026093004`
- fase 2 (`15:16:09`, 3 detik kemudian) : lewat cache **masih `10.92.2.2`**, TTL turun menjadi `12`

![alt text](<Assets/No18_%2315_fase 1 dan fase 2.png>)

- pada detik yang sama, prab langsung sudah menjawab **`192.0.2.18`**. Jadi IP lama di fase 2 memang berasal dari cache, bukan karena perubahan belum terjadi

![alt text](<Assets/No18_%2316_fase 2 sumber prab.png>)

8. fase 3, tunggu TTL habis
```bash
sleep 15
dig @127.0.0.1 abbey.K57.com
dig @10.92.1.3 abbey.K57.com +short
```
- fase 3 (`15:17:35`) : lewat cache sekarang **`192.0.2.18`** dengan TTL baru `15`. Cache lama sudah kedaluwarsa, resolver mengambil data baru dari prab
- tedd juga `192.0.2.18`, slave sudah sinkron serial `2026093004`

![alt text](<Assets/No18_%2317_fase 3.png>)

rangkuman

| Fase | Waktu (UTC) | Lewat cache beta | TTL | prab / tedd |
|------|-------------|------------------|-----|-------------|
| 1. sebelum | 15:16:06 | `10.92.2.2` | 15 | `10.92.2.2` |
| 2. dalam 15 detik | 15:16:09 | `10.92.2.2` | 12 | `192.0.2.18` |
| 3. setelah TTL | 15:17:35 | `192.0.2.18` | 15 | `192.0.2.18` |

### D. Mengembalikan zone (prab)

9. zone dibuat ulang dari `script.sh` dengan serial `2026093005`
```bash
nano /root/script.sh
```
serial baris 48 dari `2026093002` menjadi `2026093005`, baris lain tidak diubah (`abbey IN A 10.92.2.2` di script tidak pernah berubah)
- serial harus **lebih besar** dari `2026093004` (serial zone fiktif). tedd hanya mengambil zone kalau serial master lebih besar dari miliknya, jadi kalau serial lebih kecil, tedd tetap menyimpan IP fiktif

perubahan `/root/script.sh` (bagian `# 4. Forward Zone File K57.com`)

sebelum (hasil soal 19):
```bash
# 4. Forward Zone File K57.com
echo '$TTL 604800' > /etc/bind/jarkom/K57.com
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
# ... baris lain tidak berubah, termasuk:
echo 'abbey IN A 10.92.2.2' >> /etc/bind/jarkom/K57.com
```

sesudah:
```bash
# 4. Forward Zone File K57.com
echo '$TTL 604800' > /etc/bind/jarkom/K57.com
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093005 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
# ... baris lain tidak berubah, termasuk:
echo 'abbey IN A 10.92.2.2' >> /etc/bind/jarkom/K57.com
```

ringkasan perubahan (`-` baris lama, `+` baris baru):
```diff
- echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
+ echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093005 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
```
satu-satunya perubahan `script.sh` di soal 18 adalah serial. Saat dijalankan, script membuat ulang file zone dari awal, jadi `abbey 15 IN A 192.0.2.18` otomatis kembali menjadi `abbey IN A 10.92.2.2` dengan TTL default

sebelum:
![alt text](<Assets/No18_%2318_serial script sebelum revert.png>)

sesudah:
![alt text](<Assets/No18_%2319_serial revert.png>)

```bash
grep -n "SOA" /root/script.sh
bash /root/script.sh
named-checkzone K57.com /etc/bind/jarkom/K57.com
```
`loaded serial 2026093005` dan `OK`. Pesan `Err` / `W:` dari `trixie-security` adalah masalah signature repository Debian (jam node sedikit berbeda), tidak berhubungan dengan soal ini

![alt text](<Assets/No18_%2320_jalankan script revert.png>)

10. cek dari beta
```bash
dig @10.92.1.2 abbey.K57.com
dig @10.92.1.3 abbey.K57.com +short
dig @10.92.1.3 SOA K57.com +short
```
`abbey.K57.com. 604800 IN A 10.92.2.2` di prab dan tedd, serial tedd `2026093005`, zone kembali normal

![alt text](<Assets/No18_%2321_cek revert beta.png>)

riwayat serial zone `K57.com` di soal 17 - 19

| Serial | Soal | File yang diubah | Perubahan |
|--------|------|------------------|-----------|
| `2026092904` | 1 - 8 | `script.sh` | zone awal |
| `2026093001` | 17 | `script.sh` | + 5 TXT record |
| `2026093002` | 19 | `script.sh` | + CNAME `outbound` |
| `2026093003` | 18 | file zone langsung | `abbey 15 IN A 10.92.2.2` |
| `2026093004` | 18 | file zone langsung (dari `/root/K57-fiktif`) | `abbey 15 IN A 192.0.2.18` |
| `2026093005` | 18 | `script.sh` | kembali normal `abbey IN A 10.92.2.2` |

### Catatan percobaan

fase 2 baru berhasil di percobaan ke-4

- percobaan 1 : perintah di prab belum dijalankan, fase 2 masih `10.92.2.2` dengan TTL 15 karena memang belum ada perubahan
- percobaan 2 : perubahan memakai `service named restart`, fase 2 baru tercapai 21 detik setelah fase 1, cache sudah kedaluwarsa. Diganti ke `rndc reload`
- percobaan 3 : zone di prab belum dikembalikan ke TTL 15 IP asli, fase 1 sudah `192.0.2.18`

cara mengulang percobaan
```bash
# prab
cp /root/K57-ttl15 /etc/bind/jarkom/K57.com && service named restart

# beta
service named restart
dig @10.92.1.2 abbey.K57.com +short
```
lanjut fase 1 hanya kalau hasilnya `10.92.2.2`. Untuk demo ulang setelah tahap D, serial di kedua file harus dinaikkan lagi di atas `2026093005` supaya tedd ikut sinkron
