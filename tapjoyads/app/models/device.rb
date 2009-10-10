class Device < ActiveResource::Base
  self.site = "http://localhost:8888"
  self.prefix = "/device/"
end
