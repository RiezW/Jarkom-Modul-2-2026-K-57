#!/bin/bash
# Soal 19 - prab: + CNAME outbound ke http.badssl.com, serial 2026093002 (lihat soal19.md)
# 1. Install BIND9
apt-get update
apt-get install -y bind9 bind9utils

# 2. Buat folder zone
mkdir -p /etc/bind/jarkom

# 3. Buat named.conf.local (Forward + Reverse Zones)
echo 'zone "K57.com" {' > /etc/bind/named.conf.local
echo '    type master;' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/K57.com";' >> /etc/bind/named.conf.local
echo '    notify yes;' >> /etc/bind/named.conf.local
echo '    also-notify { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '    allow-transfer { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

# Reverse Zone Subnet 2 (abbey)
echo 'zone "2.92.10.in-addr.arpa" {' >> /etc/bind/named.conf.local
echo '    type master;' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/2.92.10.in-addr.arpa";' >> /etc/bind/named.conf.local
echo '    notify yes;' >> /etc/bind/named.conf.local
echo '    also-notify { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '    allow-transfer { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

# Reverse Zone Subnet 3 (penny)
echo 'zone "3.92.10.in-addr.arpa" {' >> /etc/bind/named.conf.local
echo '    type master;' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/3.92.10.in-addr.arpa";' >> /etc/bind/named.conf.local
echo '    notify yes;' >> /etc/bind/named.conf.local
echo '    also-notify { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '    allow-transfer { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

# Reverse Zone Subnet 5 (vault & core)
echo 'zone "5.92.10.in-addr.arpa" {' >> /etc/bind/named.conf.local
echo '    type master;' >> /etc/bind/named.conf.local
echo '    file "/etc/bind/jarkom/5.92.10.in-addr.arpa";' >> /etc/bind/named.conf.local
echo '    notify yes;' >> /etc/bind/named.conf.local
echo '    also-notify { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '    allow-transfer { 10.92.1.3; };' >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

# 4. Forward Zone File K57.com
echo '$TTL 604800' > /etc/bind/jarkom/K57.com
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026093002 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/K57.com
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
echo 'vault IN A 10.92.5.4' >> /etc/bind/jarkom/K57.com
echo 'vault IN A 10.92.5.5' >> /etc/bind/jarkom/K57.com
echo 'core IN A 10.92.5.6' >> /etc/bind/jarkom/K57.com
echo 'core IN A 10.92.5.7' >> /etc/bind/jarkom/K57.com
echo 'www IN CNAME penny.K57.com.' >> /etc/bind/jarkom/K57.com
echo 'static IN CNAME abbey.K57.com.' >> /etc/bind/jarkom/K57.com
echo 'alpha IN TXT "alpha"' >> /etc/bind/jarkom/K57.com
echo 'beta IN TXT "beta"' >> /etc/bind/jarkom/K57.com
echo 'gamma IN TXT "gamma"' >> /etc/bind/jarkom/K57.com
echo 'delta IN TXT "delta"' >> /etc/bind/jarkom/K57.com
echo 'epsilon IN TXT "epsilon"' >> /etc/bind/jarkom/K57.com
echo 'outbound IN CNAME http.badssl.com.' >> /etc/bind/jarkom/K57.com

# 5. Reverse Zone Files
# Reverse Subnet 2 (abbey)
echo '$TTL 604800' > /etc/bind/jarkom/2.92.10.in-addr.arpa
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026092904 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/2.92.10.in-addr.arpa
echo '@ IN NS prab.K57.com.' >> /etc/bind/jarkom/2.92.10.in-addr.arpa
echo '@ IN NS tedd.K57.com.' >> /etc/bind/jarkom/2.92.10.in-addr.arpa
echo '2 IN PTR abbey.K57.com.' >> /etc/bind/jarkom/2.92.10.in-addr.arpa

# Reverse Subnet 3 (penny)
echo '$TTL 604800' > /etc/bind/jarkom/3.92.10.in-addr.arpa
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026092904 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/3.92.10.in-addr.arpa
echo '@ IN NS prab.K57.com.' >> /etc/bind/jarkom/3.92.10.in-addr.arpa
echo '@ IN NS tedd.K57.com.' >> /etc/bind/jarkom/3.92.10.in-addr.arpa
echo '2 IN PTR penny.K57.com.' >> /etc/bind/jarkom/3.92.10.in-addr.arpa

# Reverse Subnet 5 (vault & core)
echo '$TTL 604800' > /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '@ IN SOA prab.K57.com. root.K57.com. ( 2026092904 604800 86400 2419200 604800 )' >> /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '@ IN NS prab.K57.com.' >> /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '@ IN NS tedd.K57.com.' >> /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '4 IN PTR obladi.K57.com.' >> /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '5 IN PTR desmond.K57.com.' >> /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '6 IN PTR oblada.K57.com.' >> /etc/bind/jarkom/5.92.10.in-addr.arpa
echo '7 IN PTR molly.K57.com.' >> /etc/bind/jarkom/5.92.10.in-addr.arpa

# 6. Options & Resolvers
echo 'options {' > /etc/bind/named.conf.options
echo '    directory "/var/cache/bind";' >> /etc/bind/named.conf.options
echo '    forwarders { 192.168.122.1; };' >> /etc/bind/named.conf.options
echo '    dnssec-validation no;' >> /etc/bind/named.conf.options
echo '    allow-query { any; };' >> /etc/bind/named.conf.options
echo '    auth-nxdomain no;' >> /etc/bind/named.conf.options
echo '    listen-on-v6 { any; };' >> /etc/bind/named.conf.options
echo '};' >> /etc/bind/named.conf.options

echo "nameserver 10.92.1.2" > /etc/resolv.conf
echo "nameserver 10.92.1.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

service named restart
