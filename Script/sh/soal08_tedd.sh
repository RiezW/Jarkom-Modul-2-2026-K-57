#!/bin/bash
# Soal 8 - tedd: slave forward + reverse zone (dari soal8.md)
# 1. Install BIND9
apt-get update
apt-get install -y bind9 bind9utils

# 2. Buat folder zone & set izin akses
mkdir -p /etc/bind/jarkom
chown -R bind:bind /etc/bind/jarkom/
chmod 775 /etc/bind/jarkom/

# 3. Konfigurasi Slave Zones (Forward + Reverse)
echo 'zone "K57.com" {' > /etc/bind/named.conf.local
echo '    type slave;' >> /etc/bind/named.conf.local
echo '    masters { 10.92.1.2; };' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/K57.com";' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

echo 'zone "2.92.10.in-addr.arpa" {' >> /etc/bind/named.conf.local
echo '    type slave;' >> /etc/bind/named.conf.local
echo '    masters { 10.92.1.2; };' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/2.92.10.in-addr.arpa";' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

echo 'zone "3.92.10.in-addr.arpa" {' >> /etc/bind/named.conf.local
echo '    type slave;' >> /etc/bind/named.conf.local
echo '    masters { 10.92.1.2; };' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/3.92.10.in-addr.arpa";' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

echo 'zone "5.92.10.in-addr.arpa" {' >> /etc/bind/named.conf.local
echo '    type slave;' >> /etc/bind/named.conf.local
echo '    masters { 10.92.1.2; };' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/5.92.10.in-addr.arpa";' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

# 4. Local Resolver
echo "nameserver 10.92.1.2" > /etc/resolv.conf
echo "nameserver 10.92.1.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

service named restart
