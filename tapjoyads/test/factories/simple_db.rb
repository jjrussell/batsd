FactoryGirl.define do
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

  factory :reward do
    publisher_user_id "bill"
    currency_reward    100
  end
end
