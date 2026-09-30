## Soal 17 - TXT record untuk setiap client
   dijalankan di **prab** (DNS master), otomatis tersinkron ke **tedd** (slave), testing dari **alpha**

setiap client punya TXT record yang berisi nama hostname-nya sendiri

| Nama | TXT |
|------|-----|
| `alpha.K57.com` | `"alpha"` |
| `beta.K57.com` | `"beta"` |
| `gamma.K57.com` | `"gamma"` |
| `delta.K57.com` | `"delta"` |
| `epsilon.K57.com` | `"epsilon"` |

### Sebelum

```bash
dig TXT alpha.K57.com
```
`status: NOERROR` tetapi `ANSWER: 0`. Nama `alpha.K57.com` ada (punya A record), tetapi belum punya TXT. Serial zone masih `2026092904`

![alt text](<Assets/No17_%2301_dig txt sebelum.png>)

### Konfigurasi di prab

zone `/etc/bind/jarkom/K57.com` dibuat ulang oleh `/root/script.sh` setiap kali script dijalankan, jadi perubahan dilakukan di `script.sh`, bukan langsung di file zone. Kalau hanya file zone yang diubah, TXT record akan hilang saat `script.sh` dijalankan lagi

1. buka script
```bash
nano /root/script.sh
```

2. naikkan serial zone forward `K57.com` (baris 40) dari `2026092904` menjadi `2026093001`
```bash
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093001 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
```
- tedd (slave) hanya mengambil zone baru kalau serial di prab lebih besar dari serial miliknya
- format `YYYYMMDDnn`, `2026093001` = 30 September 2026, perubahan ke-01
- hanya zone `K57.com` yang dinaikkan serialnya, zone reverse tidak berubah isinya

sebelum:
![alt text](<Assets/No17_%2302_serial lama di script prab.png>)

sesudah:
![alt text](<Assets/No17_%2303_ganti serial prab.png>)

3. tambahkan 5 baris TXT setelah baris `static IN CNAME` (baris 71 - 75)
```bash
echo 'alpha IN TXT "alpha"' >> /etc/bind/jarkom/K57.com
echo 'beta IN TXT "beta"' >> /etc/bind/jarkom/K57.com
echo 'gamma IN TXT "gamma"' >> /etc/bind/jarkom/K57.com
echo 'delta IN TXT "delta"' >> /etc/bind/jarkom/K57.com
echo 'epsilon IN TXT "epsilon"' >> /etc/bind/jarkom/K57.com
```
- `>>` menambahkan ke file zone (bukan `>` yang menghapus isi file)
- tanda kutip tunggal di luar supaya bash tidak mengubah isi, tanda kutip ganda di dalam wajib untuk nilai TXT di BIND
- `alpha` tanpa titik di akhir berarti nama relatif, BIND menambahkan nama zone menjadi `alpha.K57.com`
- satu nama boleh punya A record dan TXT record sekaligus

![alt text](<Assets/No17_%2305_tambah record txt prab.png>)

4. cek perubahan, jalankan script, dan cek file zone
```bash
grep -n "SOA\|TXT" /root/script.sh
bash /root/script.sh
named-checkzone K57.com /etc/bind/jarkom/K57.com
```
- baris 40 serial baru, baris 71 - 75 TXT record, SOA zone reverse (baris 80, 87, 94) tetap
- `script.sh` membuat ulang file zone lalu restart `named`
- `named-checkzone` : `loaded serial 2026093001` dan `OK`, file zone valid
- pesan `Err` / `W:` dari `trixie-updates` adalah masalah signature repository Debian, tidak berhubungan dengan soal ini (bind9 sudah terinstall)

![alt text](<Assets/No17_%2306_jalankan script dan checkzone prab.png>)

### Testing dari alpha

5. cek serial di master dan slave
```bash
dig @10.92.1.2 SOA K57.com +short
dig @10.92.1.3 SOA K57.com +short
```
prab (`10.92.1.2`) dan tedd (`10.92.1.3`) sama-sama `2026093001`, tedd sudah mengambil zone baru setelah restart named di prab (notify)

6. cek TXT record
```bash
dig TXT alpha.K57.com
dig TXT beta.K57.com +short
dig TXT gamma.K57.com +short
dig TXT delta.K57.com +short
dig TXT epsilon.K57.com +short
dig @10.92.1.3 TXT alpha.K57.com +short
```
- `alpha.K57.com` sekarang `ANSWER: 1`, isi `"alpha"`
- setiap client mengembalikan nama hostname-nya sendiri
- query langsung ke tedd juga mengembalikan `"alpha"`, slave ikut melayani TXT record

![alt text](<Assets/No17_%2307_test serial dan txt alpha.png>)
