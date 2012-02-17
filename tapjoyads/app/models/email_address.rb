class EmailAddress < SimpledbResource
  self.domain_name = 'email_addresses'

  self.sdb_attr :udid
  self.sdb_attr :email_address
  self.sdb_attr :created_at,   :type => :time
  self.sdb_attr :confirmed_at, :type => :time

  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
    self.created_at = Time.zone.now unless created_at?
  end

  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end

end
