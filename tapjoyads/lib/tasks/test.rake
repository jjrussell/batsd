require 'tapjoyserver-tests/tests'

namespace :test do
  desc 'Runs all QA tests'
  task :all_inside_proj do
    Tapjoyserver::Tests::Runner.run_tests
  end
end
