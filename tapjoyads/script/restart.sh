#! /bin/sh

script/poller stop
script/jobs stop
touch tmp/restart.txt
script/jobs start
script/poller start