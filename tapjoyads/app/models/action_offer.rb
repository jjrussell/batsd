class ActionOffer < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  belongs_to :app
  
  validates_presence_of :partner, :app, :name
  
  named_scope :visible, :conditions => { :hidden => false }
  
  accepts_nested_attributes_for :primary_offer
  
  after_create :create_primary_offer
  after_update :update_offers
  
  delegate :user_enabled?, :tapjoy_enabled?, :bid, :description, :min_bid, :to => :primary_offer

  def integrated?
    if defined? @integrated
      @integrated
    else
      @integrated = tapjoy_enabled? || Appstats.new(id, { :start_time => Time.zone.now.beginning_of_hour - 23.hours, :end_time => Time.zone.now, :granularity => :hourly, :stat_types => [ 'logins' ] }).stats['logins'].sum > 0
    end
  end
  
private

  def create_primary_offer
    offer                  = Offer.new(:item => self)
    offer.id               = id
    offer.partner          = partner
    offer.name             = name
    offer.instructions     = "Follow the instructions to receive credit."
    offer.url              = "#{API_URL}/action_offers/#{self.id}"
    offer.device_types     = app.primary_offer.device_types
    offer.bid              = 0
    offer.price            = 0
    offer.time_delay       = 'in seconds'
    offer.name_suffix      = 'action'
    offer.third_party_data = app_id
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id if partner_id_changed?
      offer.app_id           = app_id if app_id_changed?
      offer.name             = name if name_changed?
      offer.hidden           = hidden if hidden_changed?
      offer.third_party_data = app_id if app_id_changed?
      offer.save! if offer.changed?
    end
  end
end
