#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "nameserver 10.92.1.2" > /etc/resolv.conf
echo "nameserver 10.92.1.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf
service apache2 start
