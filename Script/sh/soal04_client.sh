#!/bin/bash
# Soal 4 - semua client: resolver prab, tedd, 192.168.122.1 (dari soal4.md)
echo "nameserver 10.92.1.2" > /etc/resolv.conf
echo "nameserver 10.92.1.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf
