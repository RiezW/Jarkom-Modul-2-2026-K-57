1. update script.sh milik prab
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

    # 4. Buat File Zone K57.com (Lengkap dengan Record No 7)
    echo '$TTL 604800' > /etc/bind/jarkom/K57.com
    echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026092903 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
    echo '@ IN NS prab.K57.com.' >> /etc/bind/jarkom/K57.com
    echo '@ IN NS tedd.K57.com.' >> /etc/bind/jarkom/K57.com
    echo '@ IN A 10.92.3.2' >> /etc/bind/jarkom/K57.com
    echo 'prab IN A 10.92.1.2' >> /etc/bind/jarkom/K57.com
    echo 'tedd IN A 10.92.1.3' >> /etc/bind/jarkom/K57.com
    echo 'abbey IN A 10.92.2.2' >> /etc/bind/jarkom/K57.com
    echo 'penny IN A 10.92.3.2' >> /etc/bind/jarkom/K57.com
    echo 'alpha IN A 10.92.4.2' >> /etc/bind/jarkom/K57.com
    echo 'beta IN A 10.92.4.3' >> /etc/bind/jarkom/K57.com
    echo 'gamma IN A 10.92.4.4' >> /etc/bind/jarkom/K57.com
    echo 'delta IN A 10.92.5.2' >> /etc/bind/jarkom/K57.com
    echo 'epsilon IN A 10.92.5.3' >> /etc/bind/jarkom/K57.com
    echo 'obladi IN A 10.92.5.4' >> /etc/bind/jarkom/K57.com
    echo 'desmond IN A 10.92.5.5' >> /etc/bind/jarkom/K57.com
    echo 'oblada IN A 10.92.5.6' >> /etc/bind/jarkom/K57.com
    echo 'molly IN A 10.92.5.7' >> /etc/bind/jarkom/K57.com

    # --- RECORD BARU NOMOR 7 ---
    # Vault (obladi & desmond)
    echo 'vault IN A 10.92.5.4' >> /etc/bind/jarkom/K57.com
    echo 'vault IN A 10.92.5.5' >> /etc/bind/jarkom/K57.com

    # Core (oblada & molly)
    echo 'core IN A 10.92.5.6' >> /etc/bind/jarkom/K57.com
    echo 'core IN A 10.92.5.7' >> /etc/bind/jarkom/K57.com

    # CNAME
    echo 'www IN CNAME penny.K57.com.' >> /etc/bind/jarkom/K57.com
    echo 'static IN CNAME abbey.K57.com.' >> /etc/bind/jarkom/K57.com

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

    # 7. Restart Service
    service named restart
    ```
    lalu jalankan ulang dengan
    ```bash
    bash /root/script.sh
    ```
2. di tedd restart service
   ```bash
   service named restart
   ```

3. uji coba di alpha
   ```bash
    nslookup www.K57.com
    nslookup static.K57.com
    nslookup vault.K57.com
    nslookup core.K57.com
    ```
    ![alt text](<Assets/No7_check alpha.png>)
4. uji coba di beta
   ```bash
    nslookup www.K57.com
    nslookup static.K57.com
    nslookup vault.K57.com
    nslookup core.K57.com
    ```
    ![alt text](<Assets/No7_check beta.png>)