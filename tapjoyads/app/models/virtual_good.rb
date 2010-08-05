class VirtualGood < SimpledbResource
  self.domain_name = 'virtual_good'
  
  self.sdb_attr :name,          :cgi_escape => true
  self.sdb_attr :description,   :cgi_escape => true
  self.sdb_attr :title,         :cgi_escape => true
  self.sdb_attr :price,         :type => :int
  self.sdb_attr :file_size,     :type => :int
  self.sdb_attr :max_purchases, :type => :int, :default_value => 1
  self.sdb_attr :ordinal,       :type => :int, :default_value => 500
  self.sdb_attr :beta,          :type => :bool
  self.sdb_attr :disabled,      :type => :bool
  self.sdb_attr :has_icon,      :type => :bool
  self.sdb_attr :has_data,      :type => :bool
  self.sdb_attr :app_id
  self.sdb_attr :apple_id
  self.sdb_attr :extra_attributes, :cgi_escape => true, :type => :json, :default_value => {}
  
  def icon_url
    "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}virtual_goods/icons/#{@key}.png"
  end
  
  def data_url
    "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}virtual_goods/data/#{@key}.zip"
  end
end