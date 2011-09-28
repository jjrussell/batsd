Factory.define :user do |user|
  user.email { Factory.next(:email) }
  user.username { |u| u.email }
  user.password 'asdf'
  user.password_confirmation 'asdf'
end

Factory.define :admin, :parent => :user do |admin|
  admin.after_build { |a| a.user_roles << UserRole.find_or_create_by_name('admin') }
  admin.after_create { |a| RoleAssignment.find_or_create_by_user_id_and_user_role_id(a.id, UserRole.find_or_create_by_name('admin').id) }
end

Factory.define :account_mgr_user, :parent => :user do |account_mgr|
  account_mgr.after_build { |a| a.user_roles << UserRole.find_or_create_by_name('account_mgr') }
  account_mgr.after_create { |a| RoleAssignment.find_or_create_by_user_id_and_user_role_id(a.id, UserRole.find_or_create_by_name('account_mgr').id) }
end

Factory.define :agency_user, :parent => :user do |agency|
  agency.after_build { |a| a.user_roles << UserRole.find_or_create_by_name('agency') }
  agency.after_create { |a| RoleAssignment.find_or_create_by_user_id_and_user_role_id(a.id, UserRole.find_or_create_by_name('agency').id) }
end

Factory.define :partner do |partner|
  partner.name { Factory.next(:name) }
end

Factory.define :payout_info do |info|
  info.signature { Factory.next(:name) }
  info.billing_name { Factory.next(:name) }
  info.tax_country { 'United States of America' }
  info.account_type { 'LLC' }
  info.tax_id { Factory.next(:name) }
  info.company_name { Factory.next(:name) }
  info.address_1 { Factory.next(:name) }
  info.address_city { Factory.next(:name) }
  info.address_state { Factory.next(:name) }
  info.address_postal_code { Factory.next(:name) }
  info.payment_country { 'United States of America' }
  info.payout_method { 'check' }
  info.association :partner
end

Factory.define :order do |order|
  order.association :partner
  order.payment_method 0
end

Factory.define :payout do |payout|
  payout.association :partner
  payout.month { Date.today.month }
  payout.year { Date.today.year }
end

Factory.define :app do |app|
  app.association :partner
  app.name { Factory.next(:name) }
  app.platform 'iphone'
  app.store_id 'whatevs'
end

Factory.define :enable_offer_request do |req|
  req.offer { Factory(:app).primary_offer }
  req.requested_by { Factory(:user) }
end

Factory.define :email_offer do |email_offer|
  email_offer.association :partner
  email_offer.name { Factory.next(:name) }
end

Factory.define :offerpal_offer do |offerpal_offer|
  offerpal_offer.association :partner
  offerpal_offer.name { Factory.next(:name) }
  offerpal_offer.offerpal_id UUIDTools::UUID.random_create.to_s
  offerpal_offer.url 'http://ws.tapjoyads.com/healthz'
  offerpal_offer.payment 100
end

Factory.define :rating_offer do |rating_offer|
  rating_offer.association :partner
  rating_offer.association :app
  rating_offer.name { Factory.next(:name) }
end

Factory.define :generic_offer do |generic_offer|
  generic_offer.association :partner
  generic_offer.name { Factory.next(:name) }
  generic_offer.url 'http://ws.tapjoyads.com/healthz?click_key=TAPJOY_GENERIC'
end

Factory.define :video_offer do |video_offer|
  video_offer.association :partner
  video_offer.name { Factory.next(:name) }
  video_offer.video_url ''
end

Factory.define :video_button do |video_button|
  video_button.association :video_offer
  video_button.name { Factory.next(:name) }
  video_button.url 'http://www.tapjoy.com'
  video_button.ordinal 1
end

Factory.define :conversion do |conversion|
  conversion.association :publisher_app, :factory => :app
  conversion.advertiser_offer { Factory(:app).primary_offer }
  conversion.reward_id UUIDTools::UUID.random_create.to_s
  conversion.reward_type Conversion::REWARD_TYPES['install']
  conversion.publisher_amount 70
  conversion.advertiser_amount -100
  conversion.tapjoy_amount 30
end

Factory.define :currency do |currency|
  currency.association :app
  currency.association :partner
  currency.name 'TAPJOY_BUCKS'
  currency.callback_url Currency::TAPJOY_MANAGED_CALLBACK_URL
end

Factory.define :monthly_accounting do |monthly_accounting|
  monthly_accounting.association :partner
  monthly_accounting.month                      { Time.zone.now.month }
  monthly_accounting.year                       { Time.zone.now.year }

  monthly_accounting.beginning_balance          { 0 }
  monthly_accounting.ending_balance             { 5 }
  monthly_accounting.website_orders             { 1 }
  monthly_accounting.invoiced_orders            { 2 }
  monthly_accounting.marketing_orders           { 3 }
  monthly_accounting.transfer_orders            { 4 }
  monthly_accounting.spend                      { 5 }

  monthly_accounting.beginning_pending_earnings { 0 }
  monthly_accounting.ending_pending_earnings    { 4 }
  monthly_accounting.payment_payouts            { 6 }
  monthly_accounting.transfer_payouts           { 7 }
  monthly_accounting.earnings                   { 9 }
  monthly_accounting.earnings_adjustments       { 0 }
end

Factory.define :user_role do |user_role|
  user_role.name { Factory.next(:name) }
end

Factory.define :rank_boost do |rank_boost|
  rank_boost.offer { Factory(:app).primary_offer }
  rank_boost.amount 1
  rank_boost.start_time { Time.zone.now }
  rank_boost.end_time { Time.zone.now + 1.hour }
end

Factory.define :action_offer do |action_offer|
  action_offer.name 'do something'
  action_offer.association :partner
  action_offer.association :app
  action_offer.instructions '1. do some stuff'
end

Factory.define :offer_event do |offer_event|
  offer_event.offer { Factory(:app).primary_offer }
  offer_event.scheduled_for 1.hour.from_now
  offer_event.user_enabled true
  offer_event.change_user_enabled true
  offer_event.daily_budget nil
  offer_event.change_daily_budget false
end

Factory.define :gamer do |gamer|
  gamer.username { Factory.next(:name) }
  gamer.email { Factory.next(:email) }
end
