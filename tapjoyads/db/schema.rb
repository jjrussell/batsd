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

ActiveRecord::Schema.define(:version => 20110927200827) do

  create_table "action_offers", :id => false, :force => true do |t|
    t.string   "id",                    :limit => 36,                    :null => false
    t.string   "partner_id",            :limit => 36,                    :null => false
    t.string   "app_id",                :limit => 36,                    :null => false
    t.string   "name",                                                   :null => false
    t.text     "instructions"
    t.boolean  "hidden",                              :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "variable_name",                                          :null => false
    t.string   "prerequisite_offer_id", :limit => 36
  end

  add_index "action_offers", ["app_id"], :name => "index_action_offers_on_app_id"
  add_index "action_offers", ["id"], :name => "index_action_offers_on_id", :unique => true
  add_index "action_offers", ["partner_id"], :name => "index_action_offers_on_partner_id"
  add_index "action_offers", ["prerequisite_offer_id"], :name => "index_action_offers_on_prerequisite_offer_id"

  create_table "admin_devices", :id => false, :force => true do |t|
    t.string   "id",          :limit => 36, :null => false
    t.string   "udid"
    t.string   "description"
    t.string   "platform"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_id",     :limit => 36
  end

  add_index "admin_devices", ["description"], :name => "index_admin_devices_on_description", :unique => true
  add_index "admin_devices", ["id"], :name => "index_admin_devices_on_id", :unique => true
  add_index "admin_devices", ["udid"], :name => "index_admin_devices_on_udid", :unique => true

  create_table "app_metadata_mappings", :id => false, :force => true do |t|
    t.string "id",              :limit => 36, :null => false
    t.string "app_id",          :limit => 36, :null => false
    t.string "app_metadata_id", :limit => 36, :null => false
  end

  add_index "app_metadata_mappings", ["app_id", "app_metadata_id"], :name => "index_app_metadata_mappings_on_app_id_and_app_metadata_id", :unique => true
  add_index "app_metadata_mappings", ["id"], :name => "index_app_metadata_mappings_on_id", :unique => true

  create_table "app_metadatas", :id => false, :force => true do |t|
    t.string   "id",                :limit => 36,                :null => false
    t.string   "name"
    t.text     "description"
    t.integer  "price",                           :default => 0
    t.string   "store_name",                                     :null => false
    t.string   "store_id",                                       :null => false
    t.integer  "age_rating"
    t.integer  "file_size_bytes"
    t.string   "supported_devices"
    t.datetime "released_at"
    t.float    "user_rating"
    t.string   "categories"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "app_metadatas", ["id"], :name => "index_app_metadatas_on_id", :unique => true
  add_index "app_metadatas", ["store_name", "store_id"], :name => "index_app_metadatas_on_store_name_and_store_id", :unique => true

  create_table "app_reviews", :id => false, :force => true do |t|
    t.string   "id",          :limit => 36, :null => false
    t.string   "app_id",      :limit => 36, :null => false
    t.string   "author_id",   :limit => 36, :null => false
    t.string   "author_type",               :null => false
    t.text     "text",                      :null => false
    t.date     "featured_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "app_reviews", ["app_id", "author_id"], :name => "index_app_reviews_on_app_id_and_author_id", :unique => true
  add_index "app_reviews", ["featured_on"], :name => "index_app_reviews_on_featured_on", :unique => true
  add_index "app_reviews", ["id"], :name => "index_app_reviews_on_id", :unique => true

  create_table "apps", :id => false, :force => true do |t|
    t.string   "id",                      :limit => 36,                    :null => false
    t.string   "partner_id",              :limit => 36,                    :null => false
    t.string   "name",                                                     :null => false
    t.text     "description"
    t.integer  "price",                                 :default => 0
    t.string   "platform"
    t.string   "store_id"
    t.text     "store_url"
    t.integer  "color"
    t.boolean  "use_raw_url",                           :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "age_rating"
    t.integer  "rotation_direction",                    :default => 0,     :null => false
    t.integer  "rotation_time",                         :default => 0,     :null => false
    t.boolean  "hidden",                                :default => false, :null => false
    t.integer  "file_size_bytes"
    t.string   "supported_devices"
    t.string   "enabled_rating_offer_id", :limit => 36
    t.string   "secret_key",                                               :null => false
    t.datetime "released_at"
    t.float    "user_rating"
    t.string   "categories"
    t.text     "countries_blacklist"
  end

  add_index "apps", ["id"], :name => "index_apps_on_id", :unique => true
  add_index "apps", ["name"], :name => "index_apps_on_name"
  add_index "apps", ["partner_id"], :name => "index_apps_on_partner_id"

  create_table "conversions", :id => false, :force => true do |t|
    t.string   "id",                  :limit => 36, :null => false
    t.string   "reward_id",           :limit => 36
    t.string   "advertiser_offer_id", :limit => 36
    t.string   "publisher_app_id",    :limit => 36, :null => false
    t.integer  "advertiser_amount",                 :null => false
    t.integer  "publisher_amount",                  :null => false
    t.integer  "tapjoy_amount",                     :null => false
    t.integer  "reward_type",                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country",             :limit => 2
  end

  add_index "conversions", ["advertiser_offer_id", "created_at", "reward_type"], :name => "index_on_advertiser_offer_id_created_at_and_reward_type"
  add_index "conversions", ["created_at"], :name => "index_conversions_on_created_at"
  add_index "conversions", ["id", "created_at"], :name => "index_conversions_on_id_and_created_at", :unique => true
  add_index "conversions", ["publisher_app_id", "created_at", "reward_type"], :name => "index_on_publisher_app_id_created_at_and_reward_type"

  create_table "currencies", :id => false, :force => true do |t|
    t.string   "id",                                         :limit => 36,                                                  :null => false
    t.string   "app_id",                                     :limit => 36,                                                  :null => false
    t.string   "name"
    t.integer  "conversion_rate",                                                                        :default => 100,   :null => false
    t.integer  "initial_balance",                                                                        :default => 0,     :null => false
    t.boolean  "has_virtual_goods",                                                                      :default => false, :null => false
    t.boolean  "only_free_offers",                                                                       :default => false, :null => false
    t.boolean  "send_offer_data",                                                                        :default => false, :null => false
    t.string   "secret_key"
    t.string   "callback_url"
    t.text     "disabled_offers",                                                                                           :null => false
    t.text     "test_devices",                                                                                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_age_rating"
    t.text     "disabled_partners",                                                                                         :null => false
    t.string   "partner_id",                                 :limit => 36,                                                  :null => false
    t.integer  "ordinal",                                                                                :default => 500,   :null => false
    t.decimal  "spend_share",                                              :precision => 8, :scale => 6, :default => 0.5,   :null => false
    t.integer  "minimum_featured_bid"
    t.decimal  "direct_pay_share",                                         :precision => 8, :scale => 6, :default => 1.0,   :null => false
    t.boolean  "banner_advertiser",                                                                      :default => false, :null => false
    t.text     "offer_whitelist",                                                                                           :null => false
    t.boolean  "use_whitelist",                                                                          :default => false, :null => false
    t.boolean  "tapjoy_enabled",                                                                         :default => false, :null => false
    t.boolean  "hide_rewarded_app_installs",                                                             :default => false, :null => false
    t.string   "minimum_hide_rewarded_app_installs_version",                                             :default => "",    :null => false
    t.string   "currency_group_id",                          :limit => 36,                                                  :null => false
    t.decimal  "rev_share_override",                                       :precision => 8, :scale => 6
    t.integer  "minimum_offerwall_bid"
    t.integer  "minimum_display_bid"
    t.boolean  "external_publisher",                                                                     :default => false, :null => false
    t.boolean  "udid_for_user_id",                                                                       :default => false, :null => false
    t.string   "reseller_id",                                :limit => 36
    t.decimal  "reseller_spend_share",                                     :precision => 8, :scale => 6
  end

  add_index "currencies", ["app_id"], :name => "index_currencies_on_app_id"
  add_index "currencies", ["currency_group_id"], :name => "index_currencies_on_currency_group_id"
  add_index "currencies", ["id"], :name => "index_currencies_on_id", :unique => true
  add_index "currencies", ["reseller_id"], :name => "index_currencies_on_reseller_id"

  create_table "currency_groups", :id => false, :force => true do |t|
    t.string   "id",                     :limit => 36,                :null => false
    t.integer  "normal_conversion_rate",               :default => 0, :null => false
    t.integer  "normal_bid",                           :default => 0, :null => false
    t.integer  "normal_price",                         :default => 0, :null => false
    t.integer  "normal_avg_revenue",                   :default => 0, :null => false
    t.integer  "random",                               :default => 0, :null => false
    t.integer  "over_threshold",                       :default => 0, :null => false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rank_boost",                           :default => 0, :null => false
    t.integer  "category_match",                       :default => 0, :null => false
  end

  add_index "currency_groups", ["id"], :name => "index_currency_groups_on_id", :unique => true

  create_table "earnings_adjustments", :id => false, :force => true do |t|
    t.string   "id",         :limit => 36, :null => false
    t.string   "partner_id", :limit => 36, :null => false
    t.integer  "amount",                   :null => false
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "earnings_adjustments", ["id"], :name => "index_earnings_adjustments_on_id", :unique => true
  add_index "earnings_adjustments", ["partner_id"], :name => "index_earnings_adjustments_on_partner_id"

  create_table "editors_picks", :id => false, :force => true do |t|
    t.string   "id",             :limit => 36,                  :null => false
    t.string   "offer_id",       :limit => 36,                  :null => false
    t.integer  "display_order",                :default => 100, :null => false
    t.string   "description",                  :default => "",  :null => false
    t.string   "internal_notes",               :default => "",  :null => false
    t.datetime "scheduled_for",                                 :null => false
    t.datetime "activated_at"
    t.datetime "expired_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "editors_picks", ["activated_at"], :name => "index_editors_picks_on_activated_at"
  add_index "editors_picks", ["expired_at"], :name => "index_editors_picks_on_expired_at"
  add_index "editors_picks", ["id"], :name => "index_editors_picks_on_id", :unique => true
  add_index "editors_picks", ["offer_id"], :name => "index_editors_picks_on_offer_id"
  add_index "editors_picks", ["scheduled_for"], :name => "index_editors_picks_on_scheduled_for"

  create_table "email_offers", :id => false, :force => true do |t|
    t.string   "id",             :limit => 36,                    :null => false
    t.string   "partner_id",     :limit => 36,                    :null => false
    t.string   "name",                                            :null => false
    t.text     "description"
    t.string   "third_party_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",                       :default => false, :null => false
  end

  add_index "email_offers", ["id"], :name => "index_email_offers_on_id", :unique => true
  add_index "email_offers", ["name"], :name => "index_email_offers_on_name"
  add_index "email_offers", ["partner_id"], :name => "index_email_offers_on_partner_id"

  create_table "employees", :id => false, :force => true do |t|
    t.string   "id",            :limit => 36,                   :null => false
    t.boolean  "active",                      :default => true, :null => false
    t.string   "first_name",                                    :null => false
    t.string   "last_name",                                     :null => false
    t.string   "title",                                         :null => false
    t.string   "email",                                         :null => false
    t.string   "superpower"
    t.string   "current_games"
    t.string   "weapon"
    t.text     "biography"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "display_order"
  end

  add_index "employees", ["email"], :name => "index_employees_on_email", :unique => true
  add_index "employees", ["id"], :name => "index_employees_on_id", :unique => true

  create_table "enable_offer_requests", :id => false, :force => true do |t|
    t.string   "id",              :limit => 36,                :null => false
    t.string   "offer_id",        :limit => 36,                :null => false
    t.string   "requested_by_id", :limit => 36,                :null => false
    t.string   "assigned_to_id",  :limit => 36
    t.integer  "status",                        :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "enable_offer_requests", ["id"], :name => "index_enable_offer_requests_on_id", :unique => true
  add_index "enable_offer_requests", ["offer_id"], :name => "index_enable_offer_requests_on_offer_id"
  add_index "enable_offer_requests", ["status"], :name => "index_enable_offer_requests_on_status"

  create_table "gamer_profiles", :id => false, :force => true do |t|
    t.string   "id",            :limit => 36, :null => false
    t.string   "gamer_id",      :limit => 36, :null => false
    t.string   "last_name"
    t.string   "first_name"
    t.string   "gender"
    t.date     "birthdate"
    t.string   "city"
    t.string   "country"
    t.string   "favorite_game"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gamer_profiles", ["gamer_id"], :name => "index_gamer_profiles_on_gamer_id", :unique => true
  add_index "gamer_profiles", ["id"], :name => "index_gamer_profiles_on_id", :unique => true

  create_table "gamers", :id => false, :force => true do |t|
    t.string   "id",                 :limit => 36,                 :null => false
    t.string   "email",                                            :null => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.string   "perishable_token"
    t.string   "referrer"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "udid"
    t.string   "confirmation_token",               :default => "", :null => false
  end

  add_index "gamers", ["confirmation_token"], :name => "index_gamers_on_confirmation_token", :unique => true
  add_index "gamers", ["email"], :name => "index_gamers_on_email", :unique => true
  add_index "gamers", ["id"], :name => "index_gamers_on_id", :unique => true
  add_index "gamers", ["perishable_token"], :name => "index_gamers_on_perishable_token"
  add_index "gamers", ["persistence_token"], :name => "index_gamers_on_persistence_token"

  create_table "generic_offers", :id => false, :force => true do |t|
    t.string   "id",               :limit => 36,                    :null => false
    t.string   "partner_id",       :limit => 36,                    :null => false
    t.string   "name",                                              :null => false
    t.text     "description"
    t.integer  "price",                          :default => 0
    t.string   "url",                                               :null => false
    t.string   "third_party_data"
    t.boolean  "hidden",                         :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "instructions"
  end

  add_index "generic_offers", ["id"], :name => "index_generic_offers_on_id", :unique => true
  add_index "generic_offers", ["partner_id"], :name => "index_generic_offers_on_partner_id"
  add_index "generic_offers", ["third_party_data"], :name => "index_generic_offers_on_third_party_data"

  create_table "internal_devices", :id => false, :force => true do |t|
    t.string   "id",               :limit => 36, :null => false
    t.string   "user_id",          :limit => 36, :null => false
    t.string   "description"
    t.string   "status"
    t.integer  "verification_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "internal_devices", ["id"], :name => "index_internal_devices_on_id", :unique => true
  add_index "internal_devices", ["user_id"], :name => "index_internal_devices_on_user_id"

  create_table "jobs", :id => false, :force => true do |t|
    t.string   "id",         :limit => 36,                      :null => false
    t.boolean  "active",                   :default => false,   :null => false
    t.string   "job_type",                                      :null => false
    t.string   "controller",                                    :null => false
    t.string   "action",                   :default => "index", :null => false
    t.string   "frequency",                                     :null => false
    t.integer  "seconds",                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jobs", ["id"], :name => "index_jobs_on_id", :unique => true

  create_table "monthly_accountings", :id => false, :force => true do |t|
    t.string   "id",                         :limit => 36, :null => false
    t.string   "partner_id",                 :limit => 36, :null => false
    t.integer  "month",                                    :null => false
    t.integer  "year",                                     :null => false
    t.integer  "beginning_balance",                        :null => false
    t.integer  "ending_balance",                           :null => false
    t.integer  "website_orders",                           :null => false
    t.integer  "invoiced_orders",                          :null => false
    t.integer  "marketing_orders",                         :null => false
    t.integer  "transfer_orders",                          :null => false
    t.integer  "spend",                                    :null => false
    t.integer  "beginning_pending_earnings",               :null => false
    t.integer  "ending_pending_earnings",                  :null => false
    t.integer  "payment_payouts",                          :null => false
    t.integer  "transfer_payouts",                         :null => false
    t.integer  "earnings",                                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "earnings_adjustments",                     :null => false
  end

  add_index "monthly_accountings", ["id"], :name => "index_monthly_accountings_on_id", :unique => true
  add_index "monthly_accountings", ["month", "year"], :name => "index_monthly_accountings_on_month_and_year"
  add_index "monthly_accountings", ["partner_id", "month", "year"], :name => "index_monthly_accountings_on_partner_id_and_month_and_year", :unique => true
  add_index "monthly_accountings", ["partner_id"], :name => "index_monthly_accountings_on_partner_id"

  create_table "news_coverages", :id => false, :force => true do |t|
    t.string   "id",           :limit => 36, :null => false
    t.datetime "published_at",               :null => false
    t.string   "link_source",                :null => false
    t.text     "link_text",                  :null => false
    t.text     "link_href",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "news_coverages", ["id"], :name => "index_news_coverages_on_id", :unique => true
  add_index "news_coverages", ["published_at"], :name => "index_news_coverages_on_published_at"

  create_table "offer_discounts", :id => false, :force => true do |t|
    t.string   "id",         :limit => 36, :null => false
    t.string   "partner_id", :limit => 36, :null => false
    t.string   "source",                   :null => false
    t.date     "expires_on",               :null => false
    t.integer  "amount",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "offer_discounts", ["id"], :name => "index_offer_discounts_on_id", :unique => true
  add_index "offer_discounts", ["partner_id"], :name => "index_offer_discounts_on_partner_id"

  create_table "offer_events", :id => false, :force => true do |t|
    t.string   "id",                  :limit => 36,                    :null => false
    t.string   "offer_id",            :limit => 36,                    :null => false
    t.integer  "daily_budget"
    t.boolean  "user_enabled"
    t.boolean  "change_daily_budget",               :default => false, :null => false
    t.boolean  "change_user_enabled",               :default => false, :null => false
    t.datetime "scheduled_for",                                        :null => false
    t.datetime "ran_at"
    t.datetime "disabled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "offer_events", ["id"], :name => "index_offer_events_on_id", :unique => true
  add_index "offer_events", ["offer_id"], :name => "index_offer_events_on_offer_id"

  create_table "offerpal_offers", :id => false, :force => true do |t|
    t.string   "id",          :limit => 36,                    :null => false
    t.string   "partner_id",  :limit => 36,                    :null => false
    t.string   "offerpal_id",                                  :null => false
    t.string   "name",                                         :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",                    :default => false, :null => false
  end

  add_index "offerpal_offers", ["id"], :name => "index_offerpal_offers_on_id", :unique => true
  add_index "offerpal_offers", ["name"], :name => "index_offerpal_offers_on_name"
  add_index "offerpal_offers", ["offerpal_id"], :name => "index_offerpal_offers_on_offerpal_id", :unique => true
  add_index "offerpal_offers", ["partner_id"], :name => "index_offerpal_offers_on_partner_id"

  create_table "offers", :id => false, :force => true do |t|
    t.string   "id",                                :limit => 36,                                                  :null => false
    t.string   "partner_id",                        :limit => 36,                                                  :null => false
    t.string   "item_id",                           :limit => 36,                                                  :null => false
    t.string   "item_type",                                                                                        :null => false
    t.string   "name",                                                                                             :null => false
    t.text     "url"
    t.integer  "price"
    t.integer  "payment",                                                                       :default => 0,     :null => false
    t.integer  "daily_budget",                                                                  :default => 0,     :null => false
    t.integer  "overall_budget",                                                                :default => 0,     :null => false
    t.text     "countries",                                                                                        :null => false
    t.text     "cities",                                                                                           :null => false
    t.text     "postal_codes",                                                                                     :null => false
    t.text     "device_types",                                                                                     :null => false
    t.boolean  "pay_per_click",                                                                 :default => false
    t.boolean  "allow_negative_balance",                                                        :default => false
    t.boolean  "user_enabled",                                                                  :default => false
    t.boolean  "tapjoy_enabled",                                                                :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "third_party_data"
    t.decimal  "conversion_rate",                                 :precision => 8, :scale => 6, :default => 0.0,   :null => false
    t.decimal  "show_rate",                                       :precision => 8, :scale => 6, :default => 1.0,   :null => false
    t.boolean  "self_promote_only",                                                             :default => false, :null => false
    t.integer  "age_rating"
    t.boolean  "featured",                                                                      :default => false, :null => false
    t.decimal  "min_conversion_rate",                             :precision => 8, :scale => 6
    t.datetime "next_stats_aggregation_time"
    t.datetime "last_stats_aggregation_time"
    t.datetime "last_daily_stats_aggregation_time"
    t.integer  "stats_aggregation_interval"
    t.text     "publisher_app_whitelist",                                                                          :null => false
    t.string   "name_suffix",                                                                   :default => ""
    t.boolean  "hidden",                                                                        :default => false, :null => false
    t.integer  "payment_range_low"
    t.integer  "payment_range_high"
    t.integer  "bid",                                                                           :default => 0,     :null => false
    t.integer  "reward_value"
    t.boolean  "multi_complete",                                                                :default => false, :null => false
    t.string   "direct_pay"
    t.boolean  "low_balance",                                                                   :default => false, :null => false
    t.integer  "min_bid_override"
    t.datetime "next_daily_stats_aggregation_time"
    t.boolean  "active",                                                                        :default => false
    t.string   "icon_id_override",                  :limit => 36
    t.text     "instructions"
    t.integer  "rank_boost",                                                                    :default => 0,     :null => false
    t.float    "normal_conversion_rate",                                                        :default => 0.0,   :null => false
    t.float    "normal_price",                                                                  :default => 0.0,   :null => false
    t.float    "normal_avg_revenue",                                                            :default => 0.0,   :null => false
    t.float    "normal_bid",                                                                    :default => 0.0,   :null => false
    t.integer  "over_threshold",                                                                :default => 0,     :null => false
    t.boolean  "rewarded",                                                                      :default => true
    t.string   "reseller_id",                       :limit => 36
    t.boolean  "cookie_tracking",                                                               :default => false, :null => false
    t.string   "min_os_version",                                                                :default => "",    :null => false
    t.text     "screen_layout_sizes",                                                                              :null => false
    t.integer  "interval",                                                                      :default => 0,     :null => false
    t.boolean  "url_overridden",                                                                :default => false, :null => false
  end

  add_index "offers", ["id"], :name => "index_offers_on_id", :unique => true
  add_index "offers", ["item_id"], :name => "index_offers_on_item_id"
  add_index "offers", ["item_type", "item_id"], :name => "index_offers_on_item_type_and_item_id"
  add_index "offers", ["name"], :name => "index_offers_on_name"
  add_index "offers", ["partner_id"], :name => "index_offers_on_partner_id"
  add_index "offers", ["user_enabled", "tapjoy_enabled"], :name => "index_offers_on_user_enabled_and_tapjoy_enabled"

  create_table "orders", :id => false, :force => true do |t|
    t.string   "id",             :limit => 36,                :null => false
    t.string   "partner_id",     :limit => 36,                :null => false
    t.string   "payment_txn_id", :limit => 36
    t.string   "refund_txn_id",  :limit => 36
    t.string   "coupon_id",      :limit => 36
    t.integer  "status",                       :default => 1, :null => false
    t.integer  "payment_method",                              :null => false
    t.integer  "amount",                       :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "note"
    t.integer  "invoice_id"
    t.string   "description"
    t.string   "note_to_client"
  end

  add_index "orders", ["created_at"], :name => "index_orders_on_created_at"
  add_index "orders", ["id"], :name => "index_orders_on_id", :unique => true
  add_index "orders", ["invoice_id"], :name => "index_orders_on_invoice_id", :unique => true
  add_index "orders", ["partner_id"], :name => "index_orders_on_partner_id"

  create_table "partner_assignments", :id => false, :force => true do |t|
    t.string "id",         :limit => 36, :null => false
    t.string "user_id",    :limit => 36, :null => false
    t.string "partner_id", :limit => 36, :null => false
  end

  add_index "partner_assignments", ["id"], :name => "index_partner_assignments_on_id", :unique => true
  add_index "partner_assignments", ["partner_id"], :name => "index_partner_assignments_on_partner_id"
  add_index "partner_assignments", ["user_id", "partner_id"], :name => "index_partner_assignments_on_user_id_and_partner_id", :unique => true

  create_table "partners", :id => false, :force => true do |t|
    t.string   "id",                         :limit => 36,                                                      :null => false
    t.string   "contact_name"
    t.string   "contact_phone"
    t.integer  "balance",                                                                :default => 0,         :null => false
    t.integer  "pending_earnings",                                                       :default => 0,         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payout_frequency",                                                       :default => "monthly", :null => false
    t.integer  "next_payout_amount",                                                     :default => 0,         :null => false
    t.string   "name"
    t.integer  "calculated_advertiser_tier"
    t.integer  "calculated_publisher_tier"
    t.integer  "custom_advertiser_tier"
    t.integer  "custom_publisher_tier"
    t.text     "account_manager_notes"
    t.text     "disabled_partners",                                                                             :null => false
    t.integer  "premier_discount",                                                       :default => 0,         :null => false
    t.string   "exclusivity_level_type"
    t.date     "exclusivity_expires_on"
    t.decimal  "transfer_bonus",                           :precision => 8, :scale => 6, :default => 0.0,       :null => false
    t.decimal  "rev_share",                                :precision => 8, :scale => 6, :default => 0.5,       :null => false
    t.decimal  "direct_pay_share",                         :precision => 8, :scale => 6, :default => 1.0,       :null => false
    t.string   "apsalar_username"
    t.string   "apsalar_api_secret"
    t.text     "apsalar_url"
    t.text     "offer_whitelist",                                                                               :null => false
    t.boolean  "use_whitelist",                                                          :default => false,     :null => false
    t.boolean  "approved_publisher",                                                     :default => false,     :null => false
    t.boolean  "apsalar_sharing_adv",                                                    :default => false,     :null => false
    t.boolean  "apsalar_sharing_pub",                                                    :default => false,     :null => false
    t.string   "reseller_id",                :limit => 36
    t.string   "billing_email"
    t.integer  "freshbooks_client_id"
  end

  add_index "partners", ["id"], :name => "index_partners_on_id", :unique => true
  add_index "partners", ["reseller_id"], :name => "index_partners_on_reseller_id"

  create_table "payout_infos", :id => false, :force => true do |t|
    t.string   "id",                  :limit => 36, :null => false
    t.string   "partner_id",          :limit => 36, :null => false
    t.string   "tax_country"
    t.string   "account_type"
    t.string   "billing_name"
    t.text     "tax_id"
    t.string   "beneficiary_name"
    t.string   "company_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "address_city"
    t.string   "address_state"
    t.string   "address_postal_code"
    t.string   "address_country"
    t.text     "bank_name"
    t.text     "bank_address"
    t.text     "bank_account_number"
    t.text     "bank_routing_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payout_method"
    t.string   "signature"
    t.string   "doing_business_as"
    t.string   "payment_country"
    t.string   "paypal_email"
  end

  add_index "payout_infos", ["id"], :name => "index_payout_infos_on_id", :unique => true
  add_index "payout_infos", ["partner_id"], :name => "index_payout_infos_on_partner_id"

  create_table "payouts", :id => false, :force => true do |t|
    t.string   "id",             :limit => 36,                :null => false
    t.integer  "amount",                       :default => 0, :null => false
    t.integer  "month",                                       :null => false
    t.integer  "year",                                        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "partner_id",     :limit => 36,                :null => false
    t.integer  "status",                       :default => 1, :null => false
    t.integer  "payment_method",               :default => 1, :null => false
  end

  add_index "payouts", ["id"], :name => "index_payouts_on_id", :unique => true
  add_index "payouts", ["partner_id"], :name => "index_payouts_on_partner_id"

  create_table "press_releases", :id => false, :force => true do |t|
    t.string   "id",               :limit => 36, :null => false
    t.datetime "published_at",                   :null => false
    t.text     "link_text",                      :null => false
    t.text     "link_href",                      :null => false
    t.string   "link_id"
    t.text     "content_title"
    t.text     "content_subtitle"
    t.text     "content_body"
    t.text     "content_about"
    t.text     "content_contact"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "press_releases", ["id"], :name => "index_press_releases_on_id", :unique => true
  add_index "press_releases", ["published_at"], :name => "index_press_releases_on_published_at"

  create_table "rank_boosts", :id => false, :force => true do |t|
    t.string   "id",         :limit => 36, :null => false
    t.string   "offer_id",   :limit => 36, :null => false
    t.datetime "start_time",               :null => false
    t.datetime "end_time",                 :null => false
    t.integer  "amount",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rank_boosts", ["id"], :name => "index_rank_boosts_on_id", :unique => true
  add_index "rank_boosts", ["offer_id"], :name => "index_rank_boosts_on_offer_id"

  create_table "rating_offers", :id => false, :force => true do |t|
    t.string   "id",          :limit => 36,                    :null => false
    t.string   "partner_id",  :limit => 36,                    :null => false
    t.string   "app_id",      :limit => 36,                    :null => false
    t.string   "name",                                         :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",                    :default => false, :null => false
  end

  add_index "rating_offers", ["app_id"], :name => "index_rating_offers_on_app_id"
  add_index "rating_offers", ["id"], :name => "index_rating_offers_on_id", :unique => true
  add_index "rating_offers", ["partner_id"], :name => "index_rating_offers_on_partner_id"

  create_table "resellers", :id => false, :force => true do |t|
    t.string   "id",                 :limit => 36,                               :null => false
    t.string   "name"
    t.decimal  "reseller_rev_share",               :precision => 8, :scale => 6, :null => false
    t.decimal  "rev_share",                        :precision => 8, :scale => 6, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resellers", ["id"], :name => "index_resellers_on_id", :unique => true

  create_table "role_assignments", :id => false, :force => true do |t|
    t.string "id",           :limit => 36, :null => false
    t.string "user_id",      :limit => 36, :null => false
    t.string "user_role_id", :limit => 36, :null => false
  end

  add_index "role_assignments", ["id"], :name => "index_role_assignments_on_id", :unique => true
  add_index "role_assignments", ["user_id", "user_role_id"], :name => "index_role_assignments_on_user_id_and_user_role_id", :unique => true

  create_table "user_roles", :id => false, :force => true do |t|
    t.string   "id",         :limit => 36, :null => false
    t.string   "name",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "employee"
  end

  add_index "user_roles", ["id"], :name => "index_user_roles_on_id", :unique => true
  add_index "user_roles", ["name"], :name => "index_user_roles_on_name", :unique => true

  create_table "users", :id => false, :force => true do |t|
    t.string   "id",                      :limit => 36,                    :null => false
    t.string   "username",                                                 :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "current_partner_id",      :limit => 36
    t.string   "perishable_token",                      :default => "",    :null => false
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "time_zone",                             :default => "UTC", :null => false
    t.boolean  "can_email",                             :default => true
    t.boolean  "receive_campaign_emails",               :default => true,  :null => false
    t.string   "api_key",                                                  :null => false
    t.string   "auth_net_cim_id"
    t.string   "reseller_id",             :limit => 36
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["id"], :name => "index_users_on_id", :unique => true
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "video_buttons", :id => false, :force => true do |t|
    t.string   "id",             :limit => 36,                   :null => false
    t.string   "video_offer_id", :limit => 36,                   :null => false
    t.string   "name",                                           :null => false
    t.string   "url",                                            :null => false
    t.integer  "ordinal"
    t.boolean  "enabled",                      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_buttons", ["id"], :name => "index_video_buttons_on_id", :unique => true
  add_index "video_buttons", ["video_offer_id"], :name => "index_video_buttons_on_video_offer_id"

  create_table "video_offers", :id => false, :force => true do |t|
    t.string   "id",         :limit => 36,                    :null => false
    t.string   "partner_id", :limit => 36,                    :null => false
    t.string   "name",                                        :null => false
    t.boolean  "hidden",                   :default => false, :null => false
    t.string   "video_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_offers", ["id"], :name => "index_video_offers_on_id", :unique => true
  add_index "video_offers", ["partner_id"], :name => "index_video_offers_on_partner_id"

end
