#!/bin/bash
# Soal 16 - alpha: stress test ApacheBench 250 request, concurrency 10
apt-get update
apt-get install -y apache2-utils
ab -n 250 -c 10 http://www.K57.com/
ab -n 250 -c 10 http://static.K57.com/
