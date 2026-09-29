1. Configure
   di rootkid ditambahkan satu line menjadi
   ```bash
    auto eth0
    iface eth0 inet dhcp
        up bash /root/script.sh #nambah line ini

    auto eth1
    iface eth1 inet static
        address 10.92.1.1
        netmask 255.255.255.0

    auto eth2
    iface eth2 inet static
        address 10.92.2.1
        netmask 255.255.255.0

    auto eth3
    iface eth3 inet static
        address 10.92.3.1
        netmask 255.255.255.0

    auto eth4
    iface eth4 inet static
        address 10.92.4.1
        netmask 255.255.255.0

    auto eth5
    iface eth5 inet static
        address 10.92.5.1
        netmask 255.255.255.0
    ```

2. Script
   
   ```bash
    cat << 'EOF' > /root/script.sh
    #!/bin/bash

    # 1. Aktifkan IP Forwarding di kernel (mode quiet)
    sysctl -q -w net.ipv4.ip_forward=1

    # 2. Konfigurasi Source NAT (MASQUERADE) via WAN (eth0)
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # 3. Izinkan lalu lintas forwarding antar-interface
    iptables -A FORWARD -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
    iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
    iptables -A FORWARD -i eth3 -o eth0 -j ACCEPT
    iptables -A FORWARD -i eth4 -o eth0 -j ACCEPT
    iptables -A FORWARD -i eth5 -o eth0 -j ACCEPT
    EOF
   ```

3. jalanin soal no 2 <br>
   di router :
   ```bash
   bash /root/script.sh
   ```
   ```bash
   iptables -t nat -L -v -n
   ```
   
   di client (apapun) :
   ```bash
   ping -c 3 8.8.8.8
   ```
4. screenshot
   ![alt text](<Assets/No2_test ping dari client.png>)