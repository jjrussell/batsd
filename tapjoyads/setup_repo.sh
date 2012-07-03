cp -v config/newrelic-test.yml config/newrelic.yml
cp -v config/database-default.yml config/database.yml
cp -v config/local-default.yml config/local.yml
[ -f "data/GeoIPCity.dat" ] || curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > data/GeoIPCity.dat
touch data/GeoIPCity.version
