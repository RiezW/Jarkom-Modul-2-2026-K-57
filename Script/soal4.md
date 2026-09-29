1. update untuk node prab di script.sh : <br>
   ```bash
    #!/bin/bash

    # 1. Install BIND9
    apt-get update
    apt-get install -y bind9 bind9utils

    # 2. Buat folder zone
    mkdir -p /etc/bind/jarkom

    # 3. Buat named.conf.local
    echo 'zone "K57.com" {' > /etc/bind/named.conf.local
    echo '    type master;' >> /etc/bind/named.conf.local
    echo '    file "/etc/bind/jarkom/K57.com";' >> /etc/bind/named.conf.local
    echo '    notify yes;' >> /etc/bind/named.conf.local
    echo '    also-notify { 10.92.1.3; };' >> /etc/bind/named.conf.local
    echo '    allow-transfer { 10.92.1.3; };' >> /etc/bind/named.conf.local
    echo '};' >> /etc/bind/named.conf.local

    # 4. Buat File Zone K57.com
    echo '$TTL 604800' > /etc/bind/jarkom/K57.com
    echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026092901 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
    echo '@ IN NS prab.K57.com.' >> /etc/bind/jarkom/K57.com
    echo '@ IN NS tedd.K57.com.' >> /etc/bind/jarkom/K57.com
    echo '@ IN A 10.92.3.2' >> /etc/bind/jarkom/K57.com
    echo 'prab IN A 10.92.1.2' >> /etc/bind/jarkom/K57.com
    echo 'tedd IN A 10.92.1.3' >> /etc/bind/jarkom/K57.com

    # 5. Buat named.conf.options
    echo 'options {' > /etc/bind/named.conf.options
    echo '    directory "/var/cache/bind";' >> /etc/bind/named.conf.options
    echo '    forwarders { 192.168.122.1; };' >> /etc/bind/named.conf.options
    echo '    dnssec-validation no;' >> /etc/bind/named.conf.options
    echo '    allow-query { any; };' >> /etc/bind/named.conf.options
    echo '    auth-nxdomain no;' >> /etc/bind/named.conf.options
    echo '    listen-on-v6 { any; };' >> /etc/bind/named.conf.options
    echo '};' >> /etc/bind/named.conf.options

    # 6. Set Local Resolver
    echo "nameserver 10.92.1.2" > /etc/resolv.conf
    echo "nameserver 10.92.1.3" >> /etc/resolv.conf
    echo "nameserver 192.168.122.1" >> /etc/resolv.conf

    service named restart
    ```

    berikan izin dan jalankan di console dengan :
    ```bash
    chmod +x /root/script.sh
    bash /root/script.sh
    ```

2. Update untuk tedd script.sh : <br>
   ```bash
    #!/bin/bash

    # 1. Install BIND9
    apt-get update
    apt-get install -y bind9 bind9utils

    # 2. Buat folder zone
    mkdir -p /etc/bind/jarkom

    # 3. Buat named.conf.local untuk zone Slave
    echo 'zone "K57.com" {' > /etc/bind/named.conf.local
    echo '    type slave;' >> /etc/bind/named.conf.local
    echo '    masters { 10.92.1.2; };' >> /etc/bind/named.conf.local
    echo '    file "/etc/bind/jarkom/K57.com";' >> /etc/bind/named.conf.local
    echo '};' >> /etc/bind/named.conf.local

    # 4. Set Local Resolver
    echo "nameserver 10.92.1.2" > /etc/resolv.conf
    echo "nameserver 10.92.1.3" >> /etc/resolv.conf
    echo "nameserver 192.168.122.1" >> /etc/resolv.conf

    service named restart
    ```

    berikan izin dan jalankan di console dengan :
    ```bash
    chmod +x /root/script.sh
    bash /root/script.sh
    ```

3. Update semua client : <br>
   ```bash
   nano /root/script.sh
   ```
   
   ```bash
    #!/bin/bash

    echo "nameserver 10.92.1.2" > /etc/resolv.conf
    echo "nameserver 10.92.1.3" >> /etc/resolv.conf
    echo "nameserver 192.168.122.1" >> /etc/resolv.conf
    ```

    berikan izin dan jalankan di console dengan :
    ```bash
    chmod +x /root/script.sh
    ```
    ```bash
    bash /root/script.sh
    ```    

4. testing dan verifikasi
   ```bash
    nslookup K57.com
    nslookup prab.K57.com
    nslookup tedd.K57.com
    ```

5. screenshot nslookup
   ![alt text](<Assets/No4_screenshot nslookup.png>)