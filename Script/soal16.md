## Soal 16 - Stress test gateway dengan ApacheBench
   dijalankan dari client **alpha**, 250 request dengan konkurensi 10 ke `www.K57.com` dan `static.K57.com`

1. install ApacheBench (paket `apache2-utils`, hanya tools, bukan web server)
```bash
apt-get update
apt-get install -y apache2-utils
ab -V
```
![alt text](<Assets/No16_%2302_cek versi ab.png>)

2. benchmark `www.K57.com` (penny, diteruskan ke obladi & desmond)
```bash
ab -n 250 -c 10 http://www.K57.com/
```
- `-n 250` : total 250 request
- `-c 10` : 10 request berjalan bersamaan
- URL harus diakhiri `/`

![alt text](<Assets/No16_%2303_benchmark www.png>)

3. benchmark `static.K57.com` (abbey, diteruskan ke oblada & molly)
```bash
ab -n 250 -c 10 http://static.K57.com/
```
![alt text](<Assets/No16_%2304_benchmark static.png>)

4. rangkuman hasil

| | `www.K57.com` (penny ke vault) | `static.K57.com` (abbey ke core) |
|--|------|------|
| Server Software | Apache/2.4.68 (backend) | nginx (abbey) |
| Complete requests | 250 | 250 |
| Failed (Connect / Receive / Exceptions) | 0 / 0 / 0 | 0 / 0 / 0 |
| Failed (Length) | 125 | 125 |
| Time taken | 0.165 s | 0.195 s |
| Requests per second | 1517.34 | 1280.25 |
| Time per request | 6.590 ms | 7.811 ms |
| Time per request (semua request konkuren) | 0.659 ms | 0.781 ms |
| 50% / 90% / 100% selesai dalam | 4 / 6 / 62 ms | 5 / 7 / 53 ms |

- semua 250 request berhasil di kedua endpoint, tidak ada kegagalan koneksi
- `static` sedikit lebih lambat karena halaman core dibuat oleh PHP setiap request, sedangkan vault hanya file HTML statis
- `Failed requests: 125` **bukan request yang gagal**. `ab` menganggap response dengan panjang berbeda dari response pertama sebagai "Length" failure. Halaman `served by obladi` (34 byte) dan `served by desmond` (35 byte) beda 1 huruf, begitu juga `oblada` dan `molly`. Tepat 125 dari 250 berarti setiap request kedua dilayani backend yang lain, yaitu load balancing round-robin dari soal 11

5. bukti pembagian beban di backend, menghitung request dari ApacheBench di access log
```bash
grep -c ApacheBench /var/log/apache2/vault_access.log
grep -c ApacheBench /var/log/nginx/core_access.log
```
obladi dan desmond masing-masing **125**:
![alt text](<Assets/No16_%2305_jumlah request vault.png>)

oblada dan molly masing-masing **125**:
![alt text](<Assets/No16_%2306_jumlah request core.png>)

6. script `/root/soal16.sh` di alpha
```bash
cat > /root/soal16.sh <<'SCRIPT'
#!/bin/bash
# Soal 16 - alpha: stress test ApacheBench 250 request, concurrency 10
apt-get update
apt-get install -y apache2-utils
ab -n 250 -c 10 http://www.K57.com/
ab -n 250 -c 10 http://static.K57.com/
SCRIPT
```
![alt text](<Assets/No16_%2307_simpan script alpha.png>)
