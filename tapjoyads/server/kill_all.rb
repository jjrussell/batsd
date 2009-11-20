#!/usr/bin/env ruby

`ps aux | grep #{ARGV.first} | awk '{print $2}' | xargs kill`