class Conversion < ActiveRecord::Base
  include UuidPrimaryKey
  
  REWARD_TYPES = {
    'offer' => 0,
    'install' => 1
  }
  
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :advertiser_app, :class_name => 'App'
  
  validates_presence_of :publisher_app
  validates_presence_of :advertiser_app, :unless => Proc.new { |conversion| conversion.advertiser_app_id.blank? }
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => [ 0, 1, 2, 999 ]
  
  before_save :sanitize_reward_id
  after_save :update_publisher_amount, :update_advertiser_amount
  
  def reward_type_string=(string)
    self.write_attribute(:reward_type, REWARD_TYPES[string])
  end
  
private
  
  def update_publisher_amount
    return true if self.publisher_amount == 0
    partner = publisher_app.partner
    partner.pending_earnings += self.publisher_amount
    partner.save!
  end
  
  def update_advertiser_amount
    return true if self.advertiser_amount == 0 || advertiser_app.nil?
    partner = advertiser_app.partner
    partner.balance += self.advertiser_amount
    partner.save!
  end
  
  def sanitize_reward_id
    begin
      UUIDTools::UUID.parse(reward_id) unless reward_id.blank?
    rescue ArgumentError
      self.reward_id = nil
    end
  end
  
end
