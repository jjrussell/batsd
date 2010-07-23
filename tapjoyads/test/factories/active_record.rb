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

Factory.define :partner do |partner|
  partner.name { Factory.next(:name) }
end

Factory.define :order do |order|
  order.association :partner
  order.payment_method 1
end

Factory.define :payout do |payout|
  payout.association :partner
  payout.month { Date.today.month }
  payout.year { Date.today.year }
end

Factory.define :app do |app|
  app.association :partner
end

Factory.define :email_offer do |email_offer|
  email_offer.association :partner
end

Factory.define :offerpal_offer do |offerpal_offer|
  offerpal_offer.association :partner
end

Factory.define :rating_offer do |rating_offer|
  rating_offer.association :partner
end

Factory.define :offer do |offer|
  
end

Factory.define :conversion do |conversion|
  
end

Factory.define :currency do |currency|
  
end

Factory.define :monthly_accounting do |monthly_accounting|
  monthly_accounting.association :partner
end
