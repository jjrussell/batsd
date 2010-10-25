class Conversion < ActiveRecord::Base
  include UuidPrimaryKey
  
  REWARD_TYPES = {
    'offer' => 0,
    'install' => 1,
    'rating' => 2,
    'generic' => 3,
    'install_jailbroken' => 4,
    'imported' => 999,
    'display_offer' => 1000,
    'display_install' => 1001,
    'display_rating' => 1002,
    'display_generic' => 1003,
    'display_install_jailbroken' => 1004,
  }
  
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :advertiser_offer, :class_name => 'Offer'
  
  validates_presence_of :publisher_app
  validates_presence_of :advertiser_offer, :unless => Proc.new { |conversion| conversion.advertiser_offer_id.blank? }
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => REWARD_TYPES.values
  
  before_save :sanitize_reward_id
  after_create :update_publisher_amount, :update_advertiser_amount
  
  named_scope :created_since, lambda { |date| { :conditions => [ "created_at >= ?", date ] } }
  named_scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }
  
  def reward_type_string=(string)
    write_attribute(:reward_type, REWARD_TYPES[string])
  end
  
  def reward_type_string_for_displayer=(string)
    write_attribute(:reward_type, REWARD_TYPES[string] + 1000)
  end
  
private
  
  def update_publisher_amount
    return true if publisher_amount == 0
    p_id = publisher_app.partner_id
    Partner.connection.execute("UPDATE partners SET pending_earnings = (pending_earnings + #{publisher_amount}) WHERE id = '#{p_id}'")
  end
  
  def update_advertiser_amount
    return true if advertiser_amount == 0 || advertiser_offer.nil?
    p_id = advertiser_offer.partner_id
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{advertiser_amount}) WHERE id = '#{p_id}'")
  end
  
  def sanitize_reward_id
    self.reward_id = nil unless reward_id =~ UUID_REGEX
  end
  
end
