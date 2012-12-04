FactoryGirl.define do
  factory :click do
    key               { FactoryGirl.generate(:guid) }
    udid              { FactoryGirl.create(:device).key }
    currency_id       { FactoryGirl.create(:currency).id }
    currency_reward   2000
    advertiser_app_id { FactoryGirl.create(:app).id }
    publisher_app_id  { Currency.find(currency_id).app.id }
    offer_id          { App.find(advertiser_app_id).offers.first.id }
  end

  factory :device do
    key               { FactoryGirl.generate(:udid) }
    apps              { }
  end

  factory :publisher_user do
    key { "#{FactoryGirl.create(:app).id}.#{FactoryGirl.generate(:name)}" }
  end

  factory :email_signup do
    email_address { FactoryGirl.generate(:email) }
  end

  factory :virtual_good do
    key  { FactoryGirl.generate(:guid) }
    name { FactoryGirl.generate(:name) }
    price 10
    max_purchases 5
  end

  factory :reward do
    publisher_user_id "bill"
    currency_reward    100
  end

  factory :device_identifier do
    key { Factory.next(:guid) }
    udid ''
  end

  factory :temporary_device do
    key     { Factory.next(:guid) }
    apps    {}
  end

  factory :game_state do
    key           { FactoryGirl.generate(:udid) }
    udids         { 5.times { [] << FactoryGirl.generate(:udid) } }
    version       1
  end

  factory :point_purchases do
    key           { FactoryGirl.generate(:udid) }
    points        100
    virtual_goods { FactoryGirl.create(:virtual_good) }
  end

  factory :game_state_mapping do
    key               { FactoryGirl.generate(:udid) }
    publisher_user_id UUIDTools::UUID.random_create.to_s
  end

  factory :support_request do
    key               { FactoryGirl.generate(:guid) }
    udid              { FactoryGirl.generate(:udid) }
    click_id          { FactoryGirl.create(:click).id }
    offer_value       10
  end

  factory :voucher do
    key                  { Factory.next(:guid) }
    click_key            { FactoryGirl.generate(:name) }
    redemption_code      { FactoryGirl.generate(:name) }
    acquired_at          { Time.zone.now }
    expires_at           { Time.zone.now + 1.day }
    barcode_url          'http://somebarcode.com'
    completed            false
    email_address        'tapjoy@tapjoy.com'
  end

  factory :cached_offer_list do
    key  { FactoryGirl.generate(:guid) }
    generated_at { Time.zone.now }
    cached_at { Time.zone.now }
    cached_offer_type 'native'
    source 's3'
    memcached_key 's3.yo'
  end
end
