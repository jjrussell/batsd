require 'rspec/core/rake_task'

namespace :rcov do

  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.spec_opts = ["--color"]

    t.rcov = true
    t.rcov_opts = %w{--rails --include views -Ispec}
  end
end
