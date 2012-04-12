require 'rspec/core/rake_task'

namespace :rcov do
  rcov_options = %w{
    --rails
    --exclude osx\/objc,gems\/,spec\/,features\/,seeds\/
    --aggregate coverage/coverage.data
  }

  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.spec_opts = ["--color"]

    t.rcov = true
    t.rcov_opts = rcov_options
    t.rcov_opts += %w{--include views -Ispec}
  end
end
