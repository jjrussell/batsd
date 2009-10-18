class App < ActiveResource::Base
  include Counter
  
  self.site = "http://localhost:8888"
  self.prefix = "/app/"
end