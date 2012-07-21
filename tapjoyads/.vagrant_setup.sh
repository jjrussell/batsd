#!/bin/bash

cd /vagrant

sudo apt-get update
sudo apt-get install libcurl4-openssl-dev gettext libsasl2-dev redis-server imagemagick libmagickwand-dev -y

# Setup repo
cp -v /vagrant/config/newrelic-test.yml /vagrant/config/newrelic.yml
cp -v /vagrant/config/database-default.yml /vagrant/config/database.yml
cp -v /vagrant/config/local-default.yml /vagrant/config/local.yml
cp -v /vagrant/config/local-default.yml /vagrant//config/local.yml
[ -f "/vagrant/data/GeoIPCity.dat" ] || curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > /vagrant/data/GeoIPCity.dat
touch /vagrant/data/GeoIPCity.version
mkdir -p /vagrant/tmp
