class App < ActiveResource::Base
  self.site = "http://localhost:8888"
  self.prefix = "/apps/"
end