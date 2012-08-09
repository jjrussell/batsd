# == Schema Information
#
# Table name: reengagement_offers
#
#  id           :string(36)      not null, primary key
#  app_id       :string(36)      not null
#  partner_id   :string(36)      not null
#  currency_id  :string(36)      not null
#  instructions :text
#  day_number   :integer(4)      not null
#  reward_value :integer(4)      not null
#  hidden       :boolean(1)      default(FALSE), not null
#  created_at   :datetime
#  updated_at   :datetime
#

class ReengagementOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

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
    offer = campaign && campaign[value]
    record.errors.add(attribute, "already exists.") if offer && offer != record
  end
  validates_each :partner_id do |record, attribute, value|
    unless value == record.app.partner_id
      record.errors.add(attribute, "must match App's Partner ID.")
    end
  end
  validates_each :currency_id do |record, attribute, value|
    unless record.app.currencies.collect(&:id).include?(value)
      record.errors.add(attribute, "must belong to App.")
    end
  end

  after_create :create_primary_offer

  after_update :update_offers

  after_save :cache_by_app_id

  delegate :instructions_overridden, :to => :primary_offer
  delegate :get_offer_device_types, :store_id, :store_url, :large_download?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  scope :visible, :conditions => { :hidden => false }
  scope :for_app, lambda { |app_id| {:conditions => [ "app_id = ?", app_id ] } }
  scope :order_by_day, :order => "day_number ASC"

  def hide!
    self.hidden = true
    save!
  end

  def self.resolve(app, currencies, reengagement_offers, params, geoip_data)
    device = Device.new( :key => params[:udid] )
    reengagement_offer = reengagement_offers.detect{ |r| !device.has_app?(r.id) }

    if reengagement_offer.try(:should_show?, device, reengagement_offers)
      device.set_last_run_time!(reengagement_offer.id)
      reengagement_offer.reward(device, params, geoip_data)
      return reengagement_offer
    end

    nil
  end

  def should_show?(device, reengagement_offers)
    return true if 0 == day_number
    previous_reengagement_offer = reengagement_offers.detect { |ro| ro.day_number + 1 == day_number }
    time_since_last_run = Time.zone.now.to_i - device.last_run_time(previous_reengagement_offer.id).to_i
    time_since_last_run >= 24.hours.to_i && time_since_last_run < 48.hours.to_i
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

  def reward(device, params, geoip_data)
    return if day_number == 0

    reward = Reward.new(:key => reward_key(device))
    reward.type              = 'reengagement'
    reward.publisher_app_id  = app_id
    reward.currency_id       = currency_id
    reward.publisher_user_id = params[:publisher_user_id]
    reward.currency_reward   = reward_value
    reward.udid              = params[:udid]
    reward.country           = geoip_data[:primary_country]
    reward.save

    Sqs.send_message(QueueNames::SEND_CURRENCY, reward.key)
  end

  def reward_key(device)
    "#{device.id}.#{id}"
  end

  def self.find_all_in_cache_by_app_id(app_id)
    Mc.distributed_get("mysql.reengagement_offers.#{app_id}.#{ReengagementOffer.acts_as_cacheable_version}")
  end

  def cache_by_app_id
    ReengagementOffer.cache_by_app_id(app_id)
  end

  def self.cache_by_app_id(app_id)
    reengagement_offers = ReengagementOffer.visible.order_by_day.for_app(app_id).to_a
    Mc.distributed_put("mysql.reengagement_offers.#{app_id}.#{ReengagementOffer.acts_as_cacheable_version}", reengagement_offers, false, 1.day)
  end

  private

  def disable_campaign
    app.disable_reengagement_campaign!
  end

  def create_primary_offer
    offer = Offer.new({
      :item             => self,
      :item_type        => 'ReengagementOffer',
      :partner          => partner,
      :name             => "#{@app.name} - Reengagement Day #{day_number}",
      :url              => app.store_url,
      :payment          => 0,
      :instructions     => instructions,
      :device_types     => app.primary_offer.device_types,
      :reward_value     => reward_value,
      :price            => 0,
      :bid              => 0,
      :name_suffix      => '',
      :third_party_data => 0,
      :icon_id_override => app.id,
      :user_enabled     => false,
      :tapjoy_enabled   => true,
    })
    offer.id = id
    offer.save!
  end

end
