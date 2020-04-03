#!/bin/bash

## nginx
sudo apt install -y nginx



## GeoIP
sudo apt install -y geoip-database-extra libgeoip1 libnginx-mod-http-geoip

cd /usr/share/GeoIP
mv -f GeoIP.dat GeoIP.dat.bak
wget https://dl.miyuru.lk/geoip/maxmind/country/maxmind.dat.gz
gunzip maxmind.dat.gz
mv -f maxmind.dat GeoIP.dat
mv -f GeoIPCity.dat GeoIPCity.dat.bak
wget https://dl.miyuru.lk/geoip/maxmind/city/maxmind.dat.gz
gunzip maxmind.dat.gz
mv -f maxmind.dat GeoIPCity.dat


## letsencrypt

## blog
sudo mkdir -p /srv/http/memogarcia.mx

git clone https://github.com/memogarcia/memogarcia.mx /srv/http/memogarcia.mx

sudo chown -R www-data:www-data /srv/http/

sudo mv -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
sudo cp /srv/http/memogarcia.mx/nginx/nginx.conf /etc/nginx/nginx.conf

sudo mv -f /etc/nginx/sites-enabled/memogarcia.mx /etc/nginx/sites-enabled/memogarcia.mx.bk
sudo cp /srv/http/memogarcia.mx/nginx/memogarcia.mx /etc/nginx/sites-enabled/memogarcia.mx

## restart nginx
sudo systemctl restart nginx