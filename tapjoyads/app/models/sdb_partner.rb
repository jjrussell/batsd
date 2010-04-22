class SdbPartner < SimpledbResource
  self.domain_name = 'partner'
  
  self.sdb_attr :apps, :type => :json
end