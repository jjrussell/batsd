# This file is used by Rack-based servers to start the application.
require ::File.expand_path('../config/environment',  __FILE__)

begin
  ## optimize unicorn to hide GC from the user request path
  require 'unicorn/oob_gc'
  use Unicorn::OobGC, 35
rescue
  # dont fail in a developer env not using unicorn
end

use Rack::FiberPool, :size => 100
run Tapjoyad::Application
