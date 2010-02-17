class VirtualGood < SimpledbResource
  self.domain_name = 'virtual_good'
  
  self.sdb_attr :price, :type => :int
end