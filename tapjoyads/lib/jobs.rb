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

#Try to Load Merb
merb_init_file = File.expand_path(File.dirname(__FILE__)+'/../config/merb_init')
if File.exists? merb_init_file
  require File.expand_path(File.dirname(__FILE__)+'/../config/boot')
  #need this because of the CWD
  Merb.root = MERB_ROOT
  require merb_init_file
else
  # Load Rails
  Rails.root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  require File.join(Rails.root, 'config', 'boot')
  require File.join(Rails.root, 'config', 'environment')
end

JobRunner.start
