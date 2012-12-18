class EmailAddress < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "email_addresses", :read_from_riak => true

  self.domain_name = 'email_addresses'

  self.sdb_attr :udid
  self.sdb_attr :email_address
  self.sdb_attr :created_at,   :type => :time
  self.sdb_attr :confirmed_at, :type => :time

  def after_initialize
    self.created_at = Time.zone.now unless created_at?
  end

end
