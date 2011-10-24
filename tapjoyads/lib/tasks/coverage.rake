require 'rcov/rcovtask'

namespace :test do
  desc 'Measures test coverage'
  task :coverage do
    mkdir 'doc/coverage' unless File.exists? 'doc/coverage'
    Dir.glob('doc/coverage/*').each { |file| remove_file file }
    system "rcov --rails --text-summary -Itest --html -o doc/coverage -x \" rubygems/*,/Library/Ruby/Site/*,gems/*,rcov*\" " <<
      %w[unit functional integration].collect { |target| FileList["test/#{target}/*_test.rb"].map { |f| "\"#{f}\"" }}.flatten.join(" ")
    system "open doc/coverage/index.html" if PLATFORM['darwin']
  end
end
