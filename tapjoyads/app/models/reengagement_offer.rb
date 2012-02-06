class ReengagementOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  belongs_to :app
  belongs_to :partner
  belongs_to :currency
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :offers, :as => :item

  validates_presence_of :partner, :app, :instructions, :reward_value
  validates_numericality_of :reward_value, :greater_than_or_equal_to => 0

  after_create :create_primary_offer
  after_update :update_offers
  after_destroy :update_offers, :uncache
  after_save :cache_list

  delegate :instructions_overridden, :to => :primary_offer
  delegate :get_offer_device_types, :store_id, :store_url, :large_download?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  named_scope :visible, :conditions => { :hidden => false }
  named_scope :active, :conditions => { :hidden => false, :enabled => true }
  named_scope :inactive, :conditions => { :hidden => false, :enabled => false }
  named_scope :for_app, lambda { |app_id| {:conditions => [ "app_id = ?", app_id ] } }

  def self.campaign_length(app_id)
    ReengagementOffer.visible.for_app(app_id).length
  end

  def campaign_length
    ReengagementOffer.campaign_length(app_id)
  end

  def self.enable_for_app!(app_id)
    ReengagementOffer.inactive.for_app(app_id).map(&:enable!)
  end

  def self.disable_for_app!(app_id)
    ReengagementOffer.active.for_app(app_id).map(&:disable!)
    ReengagementOffer.uncache_list(app_id)
  end

  def remove!
    self.hidden = true
    disable!
  end

  def uncache
    ReengagementOffer.uncache(id)
  end

  def self.uncache(id)
    Mc.delete("mysql.reengagement_offer.#{id}.#{SCHEMA_VERSION})")
  end

  def self.uncache_list(app_id)
    reengagement_offers = ReengagementOffer.active.for_app(app_id)
    reengagement_offers.map(&:uncache)
    Mc.delete("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION})")
  end

  def self.cache_list(app_id)
    reengagement_offers = ReengagementOffer.active.for_app(app_id)
    reengagement_offers.map(&:cache)
    Mc.put("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION}", reengagement_offers, false, 1.day)
  end

  def self.find_list_in_cache(app_id)
    Mc.get("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION}")
  end
  
  def cache_list
    ReengagementOffer.cache_list(app_id)
  end

  def resolve(udid, timestamp)
    device = Device.new :key => udid
    click = Click.find("#{udid}.#{id}")
    return false if click.nil? || click.successfully_rewarded? || !should_reward?(click, timestamp) && day_number > 0
    click.resolve!
    device.set_last_run_time! id
    true
  end

  def should_reward?(click, timestamp)
    # daylight-savings weirdness and leap years are not accounted for
    (Time.at(timestamp) - Time.at(click.clicked_at.to_i)) / 1.day == 1
  end

  private

  def create_reengagement_click(udid, publisher_user_id, timestamp=Time.zone.now)
    data = {
      :publisher_app      =>  App.find_in_cache(app_id),
      :udid               =>  udid,
      :publisher_user_id  =>  publisher_user_id,
      :source             =>  'reengagement',
      :currency_id        =>  currency_id,
      :viewed_at          =>  timestamp
    }
    Downloader.get_with_retry(primary_offer.click_url(data))
  end


  def disable!
    self.enabled = false
    save_enabled! and uncache if self.changed?
  end

  def enable!
    self.enabled = true
    save_enabled! and cache if self.changed?
  end

  def save_enabled!
    self.save!
    offers.each do |offer|
      offer.user_enabled = self.enabled
      offer.save!
    end
  end

  def create_primary_offer
    offer = Offer.new ({
      :item             => self,
      :partner          => partner,
      :name             => "reengagement_offer.#{app_id}.#{id}",
      :url              => app.store_url,
      :payment          => 0,
      :instructions     => instructions,
      :device_types     => app.primary_offer.device_types,
      :reward_value     => reward_value,
      :price            => 0,
      :bid              => 0,
      :name_suffix      => 'reengagement',
      :third_party_data => 0,
      :icon_id_override => app.id,
      :user_enabled     => false,
      :tapjoy_enabled   => true,
    })
    offer.id = id
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id
      offer.user_enabled     = enabled
      offer.hidden           = hidden
      offer.reward_value     = reward_value
      offer.instructions     = instructions
      offer.third_party_data = prerequisite_offer_id
      offer.save! if offer.changed?
    end
  end
  
end
