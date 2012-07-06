cp -iv config/newrelic-test.yml config/newrelic.yml
cp -iv config/database-default.yml config/database.yml
cp -iv config/local-default.yml config/local.yml
ln -ivs ../../tapjoyads/config/pre-commit ../.git/hooks/pre-commit
[ -f "data/GeoIPCity.dat" ] || curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > data/GeoIPCity.dat
