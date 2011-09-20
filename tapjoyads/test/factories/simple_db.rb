Factory.define :store_click do |click|
  click.key { "#{Factory.next(:udid)}.#{Factory.next(:guid)}" }
end

Factory.define :device do |device|
  device.key { "#{Factory.next(:udid)}" }
end

Factory.define :email_signup do |email_signup|
  email_signup.email_address { Factory.next(:email) }
end

Factory.define :virtual_good do |virtual_good|
  virtual_good.key { Factory.next(:guid) }
  virtual_good.name { Factory.next(:name) }
  virtual_good.price 10
  virtual_good.max_purchases 5
end
