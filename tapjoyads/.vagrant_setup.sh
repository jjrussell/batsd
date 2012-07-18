#!/bin/bash

cd /vagrant/tapjoyads

sudo apt-get update
sudo apt-get install libcurl4-openssl-dev gettext libsasl2-dev redis-server imagemagick libmagickwand-dev -y

# Setup repo
cp -v /vagrant/tapjoyads/config/newrelic-test.yml /vagrant/tapjoyads/config/newrelic.yml
cp -v /vagrant/tapjoyads/config/database-default.yml /vagrant/tapjoyads/config/database.yml
cp -v /vagrant/tapjoyads/config/local-default.yml /vagrant/tapjoyads/config/local.yml
cp -v /vagrant/tapjoyads/config/local-default.yml /vagrant/tapjoyads//config/local.yml
[ -f "/vagrant/tapjoyads/data/GeoIPCity.dat" ] || curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > /vagrant/tapjoyads/data/GeoIPCity.dat
touch /vagrant/tapjoyads/data/GeoIPCity.version
mkdir -p /vagrant/tapjoyads/tmp
