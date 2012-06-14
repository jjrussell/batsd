cp -v tapjoyads/config/newrelic-test.yml tapjoyads/config/newrelic.yml
cp -v tapjoyads/config/database-default.yml tapjoyads/config/database.yml
cp -v tapjoyads/config/local-default.yml tapjoyads/config/local.yml
[ -f "tapjoyads/data/GeoIPCity.dat" ] || curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > tapjoyads/data/GeoIPCity.dat
