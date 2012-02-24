class VirtualGood < SimpledbResource
  belongs_to :app

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
  self.sdb_attr :data_hash

  def initialize(options = {})
    super({ :load_from_memcache => true }.merge(options))
  end

  def save(options = {})
    super({ :write_to_memcache => true }.merge(options))
  end

  def icon_url(protocol='http://')
    "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}virtual_goods/icons/#{@key}.png"
  end

  def data_url
    "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}virtual_goods/data/#{@key}.zip"
  end

  def price_in_dollars
    return 0 if app.primary_currency.nil?
    [price.to_f / app.primary_currency_conversion_rate.to_f, 0.01].max
  end

  def <=> good
    self.ordinal <=> good.ordinal
  end
end
