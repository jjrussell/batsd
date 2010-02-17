class VirtualGood < SimpledbResource
  self.domain_name = 'virtual_good'
  
  self.sdb_attr :name,        :cgi_escape => true
  self.sdb_attr :description, :cgi_escape => true
  self.sdb_attr :title
  self.sdb_attr :price,     :type => :int
  self.sdb_attr :file_size, :type => :int
  self.sdb_attr :beta,      :type => :bool
  self.sdb_attr :disabled,  :type => :bool
end