#!/bin/bash
# Soal 4 - tedd: DNS slave zone K57.com (dari soal4.md)
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
