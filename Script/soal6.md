1. di console tedd jalankan perintah untuk update dan restart
   ```bash
   service named restart
   ```
    lalu jalankan ini untuk check file zona prab di tedd ada atau tidak
    ```bash
    ls -l /etc/bind/jarkom/
    ```

    debug
    ```bash
    chown -R bind:bind /etc/bind/jarkom/
    chmod 775 /etc/bind/jarkom/
    ```

2. screenshot step 1
   ![alt text](<Assets/No6_check file prab.png>)

3. cek SOA prab
   ```bash
   dig @10.92.1.2 K57.com SOA +short
   ```
   ![alt text](<Assets/No6_soa prab.png>)
4. cek SOA tedd
   ```bash
   dig @10.92.1.3 K57.com SOA +short
   ```
   ![alt text](<Assets/No6_soa tedd.png>)