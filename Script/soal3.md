1. script : <br>
   membuat script di /root/script.sh di semua client

   ```bash
    #!/bin/bash

    echo "nameserver 192.168.122.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    ```
    jalanin pake `bash /root/script.sh`

2. configure : <br>
   tambah line dibawah gateway
   ```bash
    up bash /root/script.sh
   ```

3. test ke google dan antar client
   ```bash
   ping -c 2 google.com
   ```
   ```bash
   ping -c 3 10.92.1.2
   ```

4. screenshot ping dns
   ![alt text](<Assets/No3_ping dns.png>)

5. screenshot ping antar client
   ![alt text](<Assets/No3_ping antar client.png>)