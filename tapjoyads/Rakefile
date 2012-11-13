# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'dotenv'

Dotenv.load

Tapjoyad::Application.load_tasks

# TODO: For newer rubygems
# Dir["#{Gem::Specification.find_by_name("annotate").full_gem_path}/**/tasks/**/*.rake"].each {|ext| load ext}
