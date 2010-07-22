Factory.sequence :name do |n|
  "Name #{n}"
end

Factory.sequence :email do |n|
  "user#{n}@tapjoy.com"
end

Factory.sequence :udid do |n|
  "#{('0' * (40 - n.to_s.length))}#{n}"
end

Factory.sequence :guid do |n|
  "#{UUIDTools::UUID.random_create}"
end
