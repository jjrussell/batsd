class Coupon < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  has_many :offers, :as => :item, :dependent => :destroy
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  validates_presence_of :provider_id, :partner_id, :name, :price
  validates_numericality_of :vouchers_expire_time_amount, :allow_nil => true
  validates_numericality_of :price, :only_integer => true, :greater_than_or_equal_to => 0

  after_create :create_primary_offer
  after_create :update_url
  after_update :update_offers

  scope :expired, :conditions => [ "end_date < ?", Date.today ]
  scope :visible, :conditions => [ "hidden = ? AND end_date > ? AND start_date <= ?", false, Date.today, Date.today ]

  def self.obtain_coupons(partner_id, price, instructions)
    coupons = (JSON.parse(%x{curl -k -X GET -H "Content-Type: application/json" -H "Accept: application/json" -H "X-ADILITY-API-KEY:#{ADILITY_KEY}" "#{ADILITY_API_URL}" }))["promotions"]
    coups = []
    coupons.each do |coupon|
      promotion = Coupon.find_all_by_provider_id_and_partner_id(coupon["id"], partner_id)
      coup = create_new_coupon(coupon, partner_id, price, instructions) if promotion.blank?
      coups << coup unless coup.blank?
    end
    coups
  end

  def vouchers
    Voucher.select(:where => "coupon_id = '#{id}'")[:items]
  end

  def get_icon_url(options = {})
    IconHandler.get_icon_url({:icon_id => IconHandler.hashed_icon_id(id)}.merge(options))
  end

  def save_icon!(icon_src_blob)
    IconHandler.upload_icon!(icon_src_blob, id)
  end

  def hide!
    self.hidden = true
    self.save!
  end

  def enabled?
    primary_offer.enabled?
  end

  def enabled=(value)
    primary_offer.user_enabled = value
    primary_offer.save!
  end

  private

  def self.create_new_coupon(coupon, partner_id, price, instructions)
    discount_type = coupon_discount_type(coupon["discount"].delete("type").to_i)
    Coupon.create!( :provider_id                 => coupon.delete("id"),
                    :name                        => coupon.delete("title"),
                    :description                 => coupon.delete("description"),
                    :fine_print                  => coupon.delete("fine_print"),
                    :illustration_url            => coupon.delete("illustration_url"),
                    :start_date                  => (Date.strptime coupon.delete("start_date"), '%Y-%m-%d'),
                    :end_date                    => (Date.strptime coupon.delete("end_date"), '%Y-%m-%d'),
                    :discount_type               => discount_type,
                    :discount_value              => discount_type == "currency" ? coupon["discount"].delete("value").to_s : coupon["discount"].delete("value").to_s + "%",
                    :advertiser_id               => coupon["advertiser"].delete("id"),
                    :advertiser_name             => coupon["advertiser"].delete("name"),
                    :advertiser_url              => coupon["advertiser"].delete("url"),
                    :vouchers_expire_type        => coupon["vouchers_expire"].delete("type"),
                    :vouchers_expire_date        => coupon["vouchers_expire"].delete("date"),
                    :vouchers_expire_time_unit   => coupon["vouchers_expire"].delete("time_unit"),
                    :vouchers_expire_time_amount => coupon["vouchers_expire"].delete("time_amount"),
                    :partner_id                  => partner_id,
                    :price                       => price,
                    :instructions                => instructions
                  )
  end

  def self.coupon_discount_type(discount_type)
    discount_type == 0 ? "currency" : "percentage"
  end

  def update_url
    self.update_attributes(:url => "#{WEBSITE_URL}/tools/coupons/#{id}")
  end

  def create_primary_offer
    offer                  = Offer.new(:item => self)
    offer.id               = id
    offer.partner          = partner
    offer.name             = name
    offer.url              = "#{WEBSITE_URL}/tools/coupons/#{id}"
    offer.instructions     = instructions
    offer.device_types     = Offer::ALL_DEVICES.to_json
    offer.price            = price
    offer.bid              = offer.min_bid
    offer.name_suffix      = 'coupon'
    offer.user_enabled     = false
    offer.tapjoy_enabled   = true
    offer.approved_sources = %w( offerwall display_ad featured tj_games )
    offer.reward_value     = nil
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id if partner_id_changed?
      offer.name             = name if name_changed?
      offer.url              = url if url_changed? && !offer.url_overridden?
      offer.price            = price if price_changed?
      offer.instructions     = instructions if instructions_changed? && !offer.instructions_overridden?
      offer.hidden           = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end
end
