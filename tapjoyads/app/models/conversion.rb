class Conversion < ActiveRecord::Base
  include UuidPrimaryKey

  REWARD_TYPES = {
    'offer' => 0,
    'install' => 1
  }

  validates_presence_of :publisher_app_id
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :reward_type, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => [ 0, 1, 2, 999 ]

  before_save :sanitize_reward_id
  after_save :update_publisher_amount, :update_advertiser_amount

  def reward_type_string=(string)
    self.write_attribute(:reward_type, REWARD_TYPES[string])
  end

private
  
  def update_publisher_amount
    return true if self.publisher_amount == 0
    app = App.new(:key => self.publisher_app_id)
    partner = Partner.find(app.partner_id)
    partner.pending_earnings += self.publisher_amount
    partner.save!
  end
  
  def update_advertiser_amount
    return true if self.advertiser_amount == 0
    app = App.new(:key => self.advertiser_app_id)
    return true if app.partner_id.nil?
    partner = Partner.find(app.partner_id)
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
