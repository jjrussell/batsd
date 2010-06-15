class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedHelper
  
  APPLE_DEVICES = %w( iphone itouch ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url, :instructions, :time_delay
  validates_numericality_of :price, :ordinal, :only_integer => true
  validates_numericality_of :payment, :only_integer => true, :if => Proc.new { |offer| offer.tapjoy_enabled? && offer.user_enabled? }
  validates_numericality_of :actual_payment, :only_integer => true, :allow_nil => true
  validates_numericality_of :conversion_rate, :show_rate, :greater_than_or_equal_to => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :credit_card_required, :self_promote_only, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer OfferpalOffer RatingOffer )
  
  named_scope :enabled_offers, { :joins => :partner, :conditions => "payment > 0 AND tapjoy_enabled = true AND user_enabled = true AND partners.balance > 0", :order => "ordinal ASC" }
  named_scope :classic_offers, { :conditions => "item_type IN ('OfferpalOffer', 'RatingOffer')", :order => "ordinal ASC" }
  
  def cost
    price > 0 ? 'Paid' : 'Free'
  end
  
  def is_paid?
    price > 0
  end
  
  def is_free?
    !is_paid?
  end
  
  def self.get_enabled_offers
    Offer.new.get_from_cache_and_save('s3.enabled_offers') do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      Marshal.restore(bucket.get('enabled_offers'))
    end
  end
  
  def self.get_classic_offers
    Offer.new.get_from_cache_and_save('s3.classic_offers') do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      Marshal.restore(bucket.get('classic_offers'))
    end
  end
  
  def self.cache_enabled_offers
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    offer_list = Offer.enabled_offers
    
    offer_list.each do |o|
      o.adjust_cvr_for_ranking
    end
    
    offer_list.sort! do |o1, o2|
      if o1.ordinal == o2.ordinal
        o2.conversion_rate <=> o1.conversion_rate
      else
        o1.ordinal <=> o2.ordinal
      end
    end
    
    bucket.put('enabled_offers', Marshal.dump(offer_list))
    Offer.new.save_to_cache('s3.enabled_offers', offer_list)
  end
  
  def self.cache_classic_offers
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    offer_list = Offer.classic_offers
    bucket.put('classic_offers', Marshal.dump(offer_list))
    Offer.new.save_to_cache('s3.classic_offers', offer_list)
  end
  
  def adjust_cvr_for_ranking
    boost = 0
    if id == '875d39dd-8227-49a2-8af4-cbd5cb583f0e'
      # MyTown: boost cvr by 20-30%
      boost = 0.2 + rand * 0.1
    elsif id == 'f8751513-67f1-4273-8e4e-73b1e685e83d'
      # Movies: boost cvr by 35-40%
      boost = 0.35 + rand * 0.05
    elsif id == '547f141c-fdf7-4953-9895-83f2545a48b4'
      # CauseWorld: US-only, so it has a low cvr. Boost it by 30-40%
      boost = 0.3 + rand * 0.1
    elsif partner_id == '70f54c6d-f078-426c-8113-d6e43ac06c6d' && is_free?
      # Tapjoy apps: reduce cvr by 5%
      boost = -0.05
    elsif is_paid?
      # Boost all paid apps by 0-15%, causing churn.
      boost = rand * 0.15
    end
    
    self.conversion_rate = pay_per_click? ? (0.75 + rand * 0.15) : (conversion_rate + boost)
  end
  
end
