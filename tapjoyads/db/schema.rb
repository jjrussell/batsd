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

ActiveRecord::Schema.define(:version => 20100405231045) do

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

  add_index "conversions", ["id"], :name => "index_conversions_on_id", :unique => true

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
    t.integer  "amount",     :default => 0, :null => false
    t.integer  "month",                     :null => false
    t.integer  "year",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payouts", ["id"], :name => "index_payouts_on_id", :unique => true

end
