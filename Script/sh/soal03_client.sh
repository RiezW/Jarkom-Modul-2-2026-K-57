#!/bin/bash
# Soal 3 - semua node non-router: resolver 192.168.122.1 (dari soal3.md)
echo "nameserver 192.168.122.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
