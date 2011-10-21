class EmailSignup < SimpledbResource
  self.domain_name = 'email_signup'
  
  self.sdb_attr :udid
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :email_address
  self.sdb_attr :postal_code
  self.sdb_attr :city
  self.sdb_attr :sent_date, :type => :time
  self.sdb_attr :confirmed, :type => :time
end
