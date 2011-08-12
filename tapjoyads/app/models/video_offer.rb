class VideoOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :offers, :as => :item
  has_many :video_buttons
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  
  validates_presence_of :partner, :name
  validates_presence_of :video_url, :unless => :new_record?
  
  before_save :update_video_url
  after_create :create_primary_offer
  after_update :update_offers
  
  named_scope :visible, :conditions => { :hidden => false }
  
private
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.price = 0
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url = video_url if video_url.present?
    offer.bid = offer.min_bid
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.url = video_url if video_url_changed?
      offer.hidden = hidden if hidden_changed?
      offer.third_party_data = xml_for_buttons  if buttons_changed?(offer.updated_at)
      offer.save! if offer.changed?
    end
  end
  
  def update_video_url
    self.video_url = Offer.get_video_url({:video_id => id})
  end
  
  def xml_for_buttons
    buttons = video_buttons.sort_by {|button| button.ordinal}
    buttons_xml = buttons.inject([]) do |result, button|
      result << button.xml_for_offer
    end
    buttons_xml.to_s
  end
  
  def buttons_changed?(updated_at)
    video_buttons.each {|button| return true if button.updated_at > updated_at}
    return false
  end
end