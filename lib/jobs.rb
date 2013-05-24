#!/usr/bin/env ruby

# This was copied extensively from the ActiveMessaging poller.

# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush


# Set the run mode.
unless ENV['RAILS_ENV']
  rails_mode = ARGV.first || "development"
  unless ["development", "test", "production"].include?(rails_mode)
    raise "Unknown rails environment '#{rails_mode}'.  (Choose 'development', 'test' or 'production')"
  end
  ENV['RAILS_ENV'] ||= rails_mode
end

# Load Rails
root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(root, 'config', 'boot')
require File.join(root, 'config', 'environment')

JobRunner.start
