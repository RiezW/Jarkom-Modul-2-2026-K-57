#!/bin/bash
# Soal 2 - rootkid: IP forwarding + NAT MASQUERADE ke internet (dari soal2.md)
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
