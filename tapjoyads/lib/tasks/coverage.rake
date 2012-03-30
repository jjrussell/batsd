require 'rcov/rcovtask'

namespace :test do
  desc  "Run all specs with rcov"
  task :coverage do
    RSpec::Core::RakeTask.new(:rcov => spec_prereq) do |t|
      t.rcov = true
      t.rcov_opts = %w{--rails --exclude osx\/objc,gems\/,spec\/,features\/}
    end
  end
end
