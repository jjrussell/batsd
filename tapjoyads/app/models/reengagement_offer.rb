class ReengagementOffer < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :app
  belongs_to :partner
  belongs_to :currency

  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :offers, :as => :item

  validates_presence_of :partner, :app, :reward_value, :day_number, :currency
  validates_presence_of :instructions, :unless => lambda { |r| r.day_number == 0 }
  validates_numericality_of :reward_value, :greater_than_or_equal_to => 0
  validates_numericality_of :day_number, :greater_than_or_equal_to => 0
  validates_each :day_number do |record, attribute, value|
    campaign = record.app.reengagement_campaign
    # puts "*" * 100
    # puts attribute
    # puts value
    offer = campaign && campaign[value]
    record.errors.add(attribute, "already exists.") if offer && offer != record
  end
  validates_each :partner_id do |record, attribute, value|
    # puts "#" * 100
    # puts attribute
    # puts value
    unless value == record.app.partner_id
      record.errors.add(attribute, "must match App's Partner ID.")
    end
  end
  validates_each :currency_id do |record, attribute, value|
    # puts "$" * 100
    # puts attribute
    # puts value
    unless record.app.currencies.collect(&:id).include?(value)
      record.errors.add(attribute, "must belong to App.")
    end
  end

  before_create :disable_campaign
  before_update :disable_campaign

  after_create :create_primary_offer

  after_update :update_offers

  delegate :instructions_overridden, :to => :primary_offer
  delegate :get_offer_device_types, :store_id, :store_url, :large_download?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  named_scope :visible, :conditions => { :hidden => false }
  named_scope :for_app, lambda { |app_id| {:conditions => [ "app_id = ?", app_id ] } }
  named_scope :order_by_day, :order => "day_number ASC"

  def remove!
    self.hidden = true
    save!
    disable_campaign
  end

  def resolve(udid, timestamp)
    device = Device.new(:key => udid)
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

  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id
      offer.user_enabled     = app.reengagement_campaign_enabled
      offer.hidden           = hidden
      offer.reward_value     = reward_value
      offer.instructions     = instructions
      offer.save! if offer.changed?
    end
  end

  private

  def disable_campaign
    app.disable_reengagement_campaign!
  end

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

  def create_primary_offer
    offer = Offer.new({
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


end
