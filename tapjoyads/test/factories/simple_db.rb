FactoryGirl.define do
  factory :store_click do
    key { "#{Factory.next(:udid)}.#{Factory.next(:guid)}" }
  end

  factory :device do
    key { "#{Factory.next(:udid)}" }
  end

  factory :email_signup do
    email_address { Factory.next(:email) }
  end

  factory :virtual_good do
    key  { Factory.next(:guid) }
    name { Factory.next(:name) }
    price 10
    max_purchases 5
  end
end
