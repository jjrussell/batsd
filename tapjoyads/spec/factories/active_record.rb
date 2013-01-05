FactoryGirl.define do
  factory :partner do
    sequence(:name) { |i| "Partner #{i}" }
    approved_publisher true
    payout_threshold 50_000_00
  end

  factory :payout_info do
    signature           { FactoryGirl.generate(:name) }
    billing_name        { FactoryGirl.generate(:name) }
    beneficiary_name    { billing_name }
    tax_country         { 'United States of America' }
    account_type        { 'LLC' }
    tax_id              { FactoryGirl.generate(:name) }
    company_name        { FactoryGirl.generate(:name) }
    address_1           { FactoryGirl.generate(:name) }
    address_city        { FactoryGirl.generate(:name) }
    address_state       { FactoryGirl.generate(:name) }
    address_postal_code { FactoryGirl.generate(:name) }
    payment_country     { 'United States of America' }
    payout_method       { 'check' }
    association         :partner
  end

  factory :order do
    association :partner
    payment_method 0
    note 'note'
  end

  factory :earnings_adjustment do
    association :partner
    amount 1
    notes 'notes'
  end

  factory :payout do
    association :partner
    month { Date.today.month }
    year  { Date.today.year }
  end

  factory :app_metadata do
    thumbs_up  0
    thumbs_down 0
    store_name 'iphone.AppStore'
    store_id   { FactoryGirl.generate(:name) }
    name       { FactoryGirl.generate(:name) }
    developer  { FactoryGirl.generate(:name) }
  end

  factory :app_metadata_mapping do
    association :app
    association :app_metadata
    is_primary  { false }
  end

  factory :reengagement_offer do
    association :currency
    app     { currency.app }
    partner { currency.partner }
    instructions 'Do some stuff.'
    reward_value 5
    day_number { FactoryGirl.generate(:integer) }
  end

  factory :deeplink_offer do
    association :currency
    app     { currency.app }
    partner { currency.partner }
  end

  factory :non_live_app, :class => App do
    association :partner
    name { FactoryGirl.generate(:name) }
    platform 'iphone'
  end

  factory :app do
    association :partner
    sequence(:name) { |i| "App #{i}" }
    platform 'iphone'
    after_build do |app|
      app.add_app_metadata(App::PLATFORM_DETAILS[app.platform][:default_store_name], FactoryGirl.generate(:name), true)
    end
  end

  factory :enable_offer_request do
    offer        { FactoryGirl.create(:app).primary_offer }
    requested_by { FactoryGirl.create(:user) }
  end

  factory :email_offer do
    association :partner
    name { FactoryGirl.generate(:name) }
  end

  factory :offerpal_offer do
    association :partner
    name { FactoryGirl.generate(:name) }
    offerpal_id UUIDTools::UUID.random_create.to_s
    url 'http://ws.tapjoyads.com/healthz'
    payment 100
  end

  factory :rating_offer do
    association :partner
    association :app
    name { FactoryGirl.generate(:name) }
  end

  factory :generic_offer do
    association :partner
    name { FactoryGirl.generate(:name) }
    url 'http://ws.tapjoyads.com/healthz?click_key=TAPJOY_GENERIC'
    category 'Social'
  end

  factory :invite_offer, :parent => :generic_offer do
    association :partner
    id TAPJOY_GAMES_INVITATION_OFFER_ID
    name { FactoryGirl.generate(:name) }
    category 'Social'
    url "#{WEBSITE_URL}/games/gamer/social?advertiser_app_id=TAPJOY_GENERIC_INVITE"
  end

  factory :video_offer do
    association :partner
    name { FactoryGirl.generate(:name) }
    video_url ''
    app_targeting false
  end

  factory :video_button do
    association :video_offer
    tracking_source_offer { FactoryGirl.create(:app).primary_offer }
    name { FactoryGirl.generate(:name) }
    url 'http://www.tapjoy.com'
    ordinal 1
    enabled true
  end

  factory :conversion do
    association :publisher_app, :factory => :app
    advertiser_offer { FactoryGirl.create(:app).primary_offer }
    reward_id UUIDTools::UUID.random_create.to_s
    reward_type Conversion::REWARD_TYPES['install']
    publisher_amount 70
    advertiser_amount -100
    tapjoy_amount 30
    publisher_partner { publisher_app.partner }
    advertiser_partner { advertiser_offer.partner }
  end

  factory :currency do
    association :app
    association :partner
    sequence(:name) { |i| "Currency #{i}" }
    callback_url Currency::TAPJOY_MANAGED_CALLBACK_URL
    conversion_rate 100
    message_enabled false
    tapjoy_enabled true
  end

  factory :unmanaged_currency, :parent => :currency do
    callback_url { FactoryGirl.generate :url }
  end

  factory :currency_group do
    id   CurrencyGroup::DEFAULT_ID
    name "default"
    normal_conversion_rate 3
    normal_bid 1
    normal_price -2
    normal_avg_revenue 5
    random 1
    over_threshold 6
    rank_boost 1
    category_match 0
  end

  factory :non_rewarded, :class => Currency do
    association :app
    association :partner
    name Currency::NON_REWARDED_NAME
    callback_url Currency::NO_CALLBACK_URL
    conversion_rate 0
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
    name { FactoryGirl.generate(:name) }
  end

  factory :rank_boost do
    offer      { FactoryGirl.create(:app).primary_offer }
    start_time { Time.zone.now }
    end_time   { Time.zone.now + 1.hour }
    amount 1
    optimized false
  end

  factory :action_offer do
    name         'do something'
    association  :app
    partner      { app.partner }
    instructions '1. do some stuff'
  end

  factory :offer_event do
    offer { FactoryGirl.create(:app).primary_offer }
    scheduled_for       1.hour.from_now
    user_enabled        true
    change_user_enabled true
    daily_budget        nil
    change_daily_budget false
  end

  factory :gamer do
    email    { FactoryGirl.generate(:email) }
    password { 'asdf' }
    password_confirmation { 'asdf' }
    terms_of_service { '1' }
    been_buried_count 0
    been_helpful_count 0
    birthdate { 13.years.ago - 1.day }
  end

  factory :gamer_device do
    name        { 'my iphone' }
    device_id   { 'test_id' }
    device_type { 'iphone' }
    gamer       { FactoryGirl.generate(:gamer) }
  end

  factory :invitation do
    gamer         { FactoryGirl.create(:gamer) }
    channel       { 0 }
    external_info { FactoryGirl.generate(:name) }
  end

  factory :reseller do
    name               { FactoryGirl.generate(:name) }
    reseller_rev_share { 0.8 }
    rev_share          { 0.75 }
  end

  factory :survey_question do
    text "what's your name?"
    format "radio"
    possible_responses "male;female"
    association :survey_offer
  end

  factory :survey_offer do
    bid  { rand(100) + 1 }
    sequence(:name) { |i| "Survey #{i}" }
  end

  factory :creative_approval_queue do
    association :user
    offer       { FactoryGirl.create(:app).primary_offer }
    size        '320x50'
  end

  factory :app_review do
    app_metadata { FactoryGirl.create(:app_metadata) }
    text         "A sample gamer review"
    user_rating  1
  end

  factory :gamer_review, :parent => :app_review do
    author { FactoryGirl.create(:gamer) }
  end

  factory :employee do
    first_name    { FactoryGirl.generate(:name) }
    last_name     { FactoryGirl.generate(:name) }
    email         { FactoryGirl.generate(:email) }
    title
    superpower    'superpower'
    current_games 'current_games'
    weapon        'weapon'
    biography     'biography'
    department    'products'
  end

  factory :employee_review, :parent => :app_review do
    author { FactoryGirl.create(:employee) }
  end

  factory :favorite_app do
    gamer         { FactoryGirl.create(:gamer) }
    app_metadata  { FactoryGirl.create(:app_metadata) }
  end

  factory :featured_content do
    featured_type         FeaturedContent::STAFFPICK
    platforms             %w( iphone itouch ).to_json
    subtitle              'Subtitle'
    title                 { generate(:name) }
    description           'Description'
    start_date            { Time.zone.now }
    end_date              { Time.zone.now + 1.day }
    weight                1
    tracking_source_offer { FactoryGirl.create(:app).primary_offer }
    author                { FactoryGirl.create(:employee) }
    button_url            'https://www.tapjoy.com'
  end

  factory :brand do
    name { FactoryGirl.generate(:name) }
  end

  factory :brand_offer_mapping do
    brand {FactoryGirl.create(:brand)}
    offer {FactoryGirl.create(:app).primary_offer }
    allocation 1
  end

  factory :client do
    name  { FactoryGirl.generate(:name) }
  end

  factory :coupon do
    association :partner
    provider_id                   { FactoryGirl.generate(:name) }
    name                          'Amazon'
    description                   'Amazing savings from Amazon'
    fine_print                    'Buy all the things!'
    illustration_url              'http://someillustration.com'
    start_date                    { Date.today }
    end_date                      { Date.today + 1.day }
    discount_type                 'currency'
    discount_value                '$30.00'
    advertiser_id                 'amazon'
    advertiser_name               'Amazon'
    advertiser_url                'http://amazon.com'
    vouchers_expire_type          'absolute'
    vouchers_expire_date          { Time.zone.now + 1.day }
    url                           'http://tapjoy.com/coupons/show'
    instructions                  'do some stuff'
    price                         1
  end

  factory :experiment do
    name              { FactoryGirl.generate(:name) }
    owner             { Factory(:user) }
    description       'Experiment Description'
    started_at        Date.today.advance(:days => 2)
    due_at            Date.today.advance(:days => 10)
    ratio             50
    population_size   1
    bucket_type       'optimization'
  end

  factory :experiment_bucket do
    bucket_type 'optimization'
  end

  factory :kontagent_integration_request do
    association   :partner
    id            { FactoryGirl.generate(:integer) }
    successful    false
    subdomain     { FactoryGirl.generate(:name).downcase.gsub(' ','') }
  end

  factory :conversion_rate do
    association :currency
    rate                  100
    minimum_offerwall_bid 50
  end

  factory :currency_sale do
    association :currency
    start_time            { Time.zone.now }
    end_time              { Time.zone.now + 1.day }
    multiplier            2
  end
end
