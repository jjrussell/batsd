require 'tapjoyserver-tests/tests'

namespace :qa do

  desc "Runs the watir tests"
  task :watir, :url do |t, args|
    url = args[:url] || 'staging.tapjoy.com/games'
    Tapjoyserver::Tests::run_tests(url)
  end

end
