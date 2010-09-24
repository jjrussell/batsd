class GenericOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  
  validates_presence_of :partner, :name, :url
  
  after_create :create_primary_offer
  after_update :update_offers
  after_save :update_memcached
  before_destroy :clear_memcached
  
  named_scope :visible, :conditions => { :hidden => false }
  
  def self.find_in_cache(id, do_lookup = true)
    if do_lookup
      Mc.get_and_put("mysql.generic_offer.#{id}") { GenericOffer.find(id) }
    else
      Mc.get("mysql.generic_offer.#{id}")
    end
  end
  
private
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = price
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url = url
    offer.third_party_data = third_party_data
    offer.instructions = 'Complete the offer.'
    offer.time_delay = 'some time'
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.description = description if description_changed?
      offer.price = price if price_changed?
      offer.url = url if url_changed?
      offer.third_party_data = third_party_data if third_party_data_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end
  
  def update_memcached
    Mc.put("mysql.generic_offer.#{id}", self)
  end
  
  def clear_memcached
    Mc.delete("mysql.generic_offer.#{id}")
  end
  
end
