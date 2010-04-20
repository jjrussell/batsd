# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100420180252) do

  create_table "apps", :force => true do |t|
    t.string   "partner_id",            :limit => 36,                    :null => false
    t.string   "name",                                                   :null => false
    t.text     "description"
    t.integer  "price",                               :default => 0
    t.string   "platform"
    t.string   "store_id"
    t.text     "store_url"
    t.integer  "color"
    t.boolean  "use_raw_url",                         :default => false, :null => false
    t.datetime "first_pinged_at"
    t.datetime "submitted_to_store_at"
    t.datetime "approved_by_store_at"
    t.datetime "approved_by_tapjoy_at"
    t.datetime "enabled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "apps", ["id"], :name => "index_apps_on_id", :unique => true
  add_index "apps", ["name"], :name => "index_apps_on_name"
  add_index "apps", ["partner_id"], :name => "index_apps_on_partner_id"

  create_table "conversions", :force => true do |t|
    t.string   "reward_id",         :limit => 36
    t.string   "advertiser_app_id", :limit => 36
    t.string   "publisher_app_id",  :limit => 36, :null => false
    t.integer  "advertiser_amount",               :null => false
    t.integer  "publisher_amount",                :null => false
    t.integer  "tapjoy_amount",                   :null => false
    t.integer  "reward_type",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "conversions", ["advertiser_app_id"], :name => "index_conversions_on_advertiser_app_id"
  add_index "conversions", ["created_at"], :name => "index_conversions_on_created_at"
  add_index "conversions", ["id"], :name => "index_conversions_on_id", :unique => true
  add_index "conversions", ["publisher_app_id"], :name => "index_conversions_on_publisher_app_id"
  add_index "conversions", ["reward_id"], :name => "index_conversions_on_reward_id"

  create_table "email_offers", :force => true do |t|
    t.string   "partner_id",     :limit => 36, :null => false
    t.string   "name",                         :null => false
    t.text     "description"
    t.string   "third_party_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_offers", ["id"], :name => "index_email_offers_on_id", :unique => true
  add_index "email_offers", ["name"], :name => "index_email_offers_on_name"
  add_index "email_offers", ["partner_id"], :name => "index_email_offers_on_partner_id"

  create_table "offers", :force => true do |t|
    t.string   "partner_id",             :limit => 36,                    :null => false
    t.string   "item_id",                :limit => 36,                    :null => false
    t.string   "item_type",                                               :null => false
    t.string   "name",                                                    :null => false
    t.text     "description"
    t.text     "url"
    t.integer  "price"
    t.integer  "payment"
    t.integer  "actual_payment"
    t.integer  "daily_budget"
    t.integer  "overall_budget"
    t.integer  "ordinal",                              :default => 500,   :null => false
    t.text     "countries"
    t.text     "cities"
    t.text     "postal_codes"
    t.text     "device_types"
    t.boolean  "pay_per_click",                        :default => false
    t.boolean  "allow_negative_balance",               :default => false
    t.boolean  "user_enabled"
    t.boolean  "tapjoy_enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "offers", ["id"], :name => "index_offers_on_id", :unique => true
  add_index "offers", ["item_id"], :name => "index_offers_on_item_id", :unique => true
  add_index "offers", ["item_type", "item_id"], :name => "index_offers_on_item_type_and_item_id", :unique => true
  add_index "offers", ["name"], :name => "index_offers_on_name"
  add_index "offers", ["ordinal"], :name => "index_offers_on_ordinal"
  add_index "offers", ["partner_id"], :name => "index_offers_on_partner_id"
  add_index "offers", ["user_enabled", "tapjoy_enabled"], :name => "index_offers_on_user_enabled_and_tapjoy_enabled"

  create_table "orders", :force => true do |t|
    t.string   "partner_id",     :limit => 36,                :null => false
    t.string   "payment_txn_id", :limit => 36
    t.string   "refund_txn_id",  :limit => 36
    t.string   "coupon_id",      :limit => 36
    t.integer  "status",                       :default => 1, :null => false
    t.integer  "payment_method",                              :null => false
    t.integer  "amount",                       :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders", ["created_at"], :name => "index_orders_on_created_at"
  add_index "orders", ["id"], :name => "index_orders_on_id", :unique => true
  add_index "orders", ["partner_id"], :name => "index_orders_on_partner_id"

  create_table "partners", :force => true do |t|
    t.string   "contact_name"
    t.string   "contact_phone"
    t.integer  "balance",          :default => 0, :null => false
    t.integer  "pending_earnings", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "partners", ["id"], :name => "index_partners_on_id", :unique => true

  create_table "payouts", :force => true do |t|
    t.integer  "amount",                   :default => 0, :null => false
    t.integer  "month",                                   :null => false
    t.integer  "year",                                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "partner_id", :limit => 36,                :null => false
    t.integer  "status",                   :default => 1, :null => false
  end

  add_index "payouts", ["id"], :name => "index_payouts_on_id", :unique => true
  add_index "payouts", ["partner_id"], :name => "index_payouts_on_partner_id"

  create_table "role_assignments", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.integer  "user_role_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_roles", ["name"], :name => "index_user_roles_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "partner_id",        :limit => 36, :null => false
    t.string   "username"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["partner_id"], :name => "index_users_on_partner_id"

end
