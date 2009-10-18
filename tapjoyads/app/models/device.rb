class Device < ActiveResource::Base
  include Counter
  
  self.site = "http://localhost:8888"
  self.prefix = "/device/"
end
