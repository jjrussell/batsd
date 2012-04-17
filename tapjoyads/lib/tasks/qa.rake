require 'tapjoyserver-tests/tests'

namespace :qa do

  desc "Runs the watir tests"
  task :watir, :host do |t, args|
    host = args[:host] || 'staging.tapjoy.com'
    Tapjoyserver::Tests::run_tests(host)
  end

end
