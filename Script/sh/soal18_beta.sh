#!/bin/bash
# Soal 18 - beta: resolver cache (bind9 forward only ke prab) untuk percobaan TTL (dari soal18.md)
apt-get update
apt-get install -y bind9

cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    forwarders { 10.92.1.2; };
    forward only;
    dnssec-validation no;
    prefetch 0;
    allow-query { any; };
};
EOF
service named restart
