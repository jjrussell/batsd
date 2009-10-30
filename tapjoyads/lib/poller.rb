#!/usr/bin/env ruby
# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush


# Add support for running poller in production mode.
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
  RAILS_ROOT=File.expand_path(File.join(File.dirname(__FILE__), '..'))
  require File.join(RAILS_ROOT, 'config', 'boot')
  require File.join(RAILS_ROOT, 'config', 'environment')
end

# Load ActiveMessaging processors
#ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start
