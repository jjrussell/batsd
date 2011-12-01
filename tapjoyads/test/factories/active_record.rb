FactoryGirl.define do
  factory :user do
    email    { Factory.next(:email) }
    username { |u| u.email }
    password 'asdf'
    password_confirmation 'asdf'
  end

  factory :admin, :parent => :user do
    after_build  { |a| a.user_roles << UserRole.find_or_create_by_name('admin') }
  end

  factory :account_mgr_user, :parent => :user do
    after_build  { |a| a.user_roles << UserRole.find_or_create_by_name('account_mgr') }
  end

  factory :agency_user, :parent => :user do
    after_build  { |a| a.user_roles << UserRole.find_or_create_by_name('agency') }
  end

  factory :partner do
    name { Factory.next(:name) }
    approved_publisher true
  end

  factory :payout_info do
    signature           { Factory.next(:name) }
    billing_name        { Factory.next(:name) }
    beneficiary_name    { billing_name }
    tax_country         { 'United States of America' }
    account_type        { 'LLC' }
    tax_id              { Factory.next(:name) }
    company_name        { Factory.next(:name) }
    address_1           { Factory.next(:name) }
    address_city        { Factory.next(:name) }
    address_state       { Factory.next(:name) }
    address_postal_code { Factory.next(:name) }
    payment_country     { 'United States of America' }
    payout_method       { 'check' }
    association         :partner
  end

  factory :order do
    association :partner
    payment_method 0
  end

  factory :payout do
    association :partner
    month { Date.today.month }
    year  { Date.today.year }
  end

  factory :app do
    association :partner
    name { Factory.next(:name) }
    platform 'iphone'
    store_id 'whatevs'
  end

  factory :enable_offer_request do
    offer        { Factory(:app).primary_offer }
    requested_by { Factory(:user) }
  end

  factory :email_offer do
    association :partner
    name { Factory.next(:name) }
  end

  factory :offerpal_offer do
    association :partner
    name { Factory.next(:name) }
    offerpal_id UUIDTools::UUID.random_create.to_s
    url 'http://ws.tapjoyads.com/healthz'
    payment 100
  end

  factory :rating_offer do
    association :partner
    association :app
    name { Factory.next(:name) }
  end

  factory :generic_offer do
    association :partner
    name { Factory.next(:name) }
    url 'http://ws.tapjoyads.com/healthz?click_key=TAPJOY_GENERIC'
  end

  factory :video_offer do
    association :partner
    name { Factory.next(:name) }
    video_url ''
  end

  factory :video_button do
    association :video_offer
    name { Factory.next(:name) }
    url 'http://www.tapjoy.com'
    ordinal 1
  end

  factory :conversion do
    association :publisher_app, :factory => :app
    advertiser_offer { Factory(:app).primary_offer }
    reward_id UUIDTools::UUID.random_create.to_s
    reward_type Conversion::REWARD_TYPES['install']
    publisher_amount 70
    advertiser_amount -100
    tapjoy_amount 30
  end

  factory :currency do
    association :app
    association :partner
    name 'TAPJOY_BUCKS'
    callback_url Currency::TAPJOY_MANAGED_CALLBACK_URL
  end

  factory :monthly_accounting do
    association :partner
    month                      { Time.zone.now.month }
    year                       { Time.zone.now.year }

    beginning_balance          { 0 }
    ending_balance             { 5 }
    website_orders             { 1 }
    invoiced_orders            { 2 }
    marketing_orders           { 3 }
    transfer_orders            { 4 }
    spend                      { 5 }

    beginning_pending_earnings { 0 }
    ending_pending_earnings    { 4 }
    payment_payouts            { 6 }
    transfer_payouts           { 7 }
    earnings                   { 9 }
    earnings_adjustments       { 0 }
  end

  factory :user_role do
    name { Factory.next(:name) }
  end

  factory :rank_boost do
    offer      { Factory(:app).primary_offer }
    start_time { Time.zone.now }
    end_time   { Time.zone.now + 1.hour }
    amount 1
  end

  factory :action_offer do
    name         'do something'
    association  :partner
    association  :app
    instructions '1. do some stuff'
  end

  factory :offer_event do
    offer { Factory(:app).primary_offer }
    scheduled_for       1.hour.from_now
    user_enabled        true
    change_user_enabled true
    daily_budget        nil
    change_daily_budget false
  end

  factory :gamer do
    email    { Factory.next(:email) }
    password { 'asdf' }
    password_confirmation { 'asdf' }
    terms_of_service { '1' }
  end

  factory :invitation do
    gamer         { Factory(:facebook_gamer) }
    noob          { Factory(:gamer) }
    channel       { 0 }
    external_info { Factory.next(:name) }
  end

  factory :reseller do
    name               { Factory.next(:name) }
    reseller_rev_share { 0.8 }
    rev_share          { 0.75 }
  end
end
