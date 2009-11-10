#!/bin/sh

mv log/production.log log/production_old.log
script/restart.sh
