# +-------------------------+--------------+------+-----+---------+-------+
# | Field                   | Type         | Null | Key | Default | Extra |
# +-------------------------+--------------+------+-----+---------+-------+
# | id                      | varchar(36)  | NO   | PRI | NULL    |       |
# | username                | varchar(255) | NO   | UNI | NULL    |       |
# | email                   | varchar(255) | YES  | MUL | NULL    |       |
# | crypted_password        | varchar(255) | YES  |     | NULL    |       |
# | password_salt           | varchar(255) | YES  |     | NULL    |       |
# | persistence_token       | varchar(255) | YES  | MUL | NULL    |       |
# | created_at              | datetime     | YES  |     | NULL    |       |
# | updated_at              | datetime     | YES  |     | NULL    |       |
# | current_partner_id      | varchar(36)  | YES  |     | NULL    |       |
# | perishable_token        | varchar(255) | NO   | MUL |         |       |
# | current_login_at        | datetime     | YES  |     | NULL    |       |
# | last_login_at           | datetime     | YES  |     | NULL    |       |
# | time_zone               | varchar(255) | NO   |     | UTC     |       |
# | can_email               | tinyint(1)   | YES  |     | 1       |       |
# | receive_campaign_emails | tinyint(1)   | NO   |     | 1       |       |
# | api_key                 | varchar(255) | NO   |     | NULL    |       |
# | auth_net_cim_id         | varchar(255) | YES  |     | NULL    |       |
# | reseller_id             | varchar(36)  | YES  |     | NULL    |       |
# | state                   | varchar(255) | YES  |     | NULL    |       |
# | country                 | varchar(255) | YES  |     | NULL    |       |
# | account_type            | varchar(255) | YES  |     | NULL    |       |
# +-------------------------+--------------+------+-----+---------+-------+
# 21 rows in set (0.00 sec)

DEFAULT_FACTORY_PASSWORD = 'password'

# Requires that test DB be seeded.
# TODO: Use seeds
ROLES = UserRole.all.map(&:name)

def email_for(role, index=nil)
  "#{role}#{index == 1 ? '' : i.to_s}@tapjoy.com"
end

def grant(user, role)
  user.user_roles << UserRole.find_by_name(role)
end

def generate(*params)
  FactoryGirl.generate(*params)
end

FactoryGirl.define do
  factory :user do
    email
    username              { |u| u.email }
    password              DEFAULT_FACTORY_PASSWORD
    password_confirmation DEFAULT_FACTORY_PASSWORD
    country

    trait(:american) do
      country 'United States of America'
    end

    trait(:with_partner) do
      association :current_partner, :factory => :partner
      after_build { |user| user.partners << user.current_partner }
    end

    trait(:premier) do
      with_partner
      after_build do |user|
        OfferDiscount.create!(:partner => user.current_partner, :source => 'Exclusivity', :amount => 1, :expires_on => 8.days.from_now)
      end
    end

    ROLES.each do |role|
      trait :"with_#{role}_role" do
        after_build { |user| grant(user, role) }
      end
    end

    trait :typical do
      american
      with_partner
    end

    factory :typical_user,             :traits => [:typical]
    factory :admin,                    :traits => [:with_admin_role]
    factory :agency,                   :traits => [:with_agency_role]
    factory :account_manager,          :traits => [:with_partner, :with_account_mgr_role]
    factory :customer_service_manager, :traits => [:with_customer_service_manager_role]
    factory :optimized_rank_booster,   :traits => [:with_optimized_rank_booster_role]
    factory :payout_manager,           :traits => [:with_payout_manager_role]
    factory :role_manager,             :traits => [:with_role_mgr_role]

    after_create do |user|
      User.stub(:find_in_cache).with(user.id).and_return(user)
    end
  end
end
