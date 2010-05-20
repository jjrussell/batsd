class Conversion < ActiveRecord::Base
  include UuidPrimaryKey
  
  REWARD_TYPES = {
    'offer' => 0,
    'install' => 1,
    'rating' => 2,
    'imported' => 999
  }
  
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :advertiser_offer, :class_name => 'Offer'
  
  validates_presence_of :publisher_app
  validates_presence_of :advertiser_offer, :unless => Proc.new { |conversion| conversion.advertiser_offer_id.blank? }
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => [ 0, 1, 2, 999 ]
  
  before_save :sanitize_reward_id
  after_create :update_publisher_amount, :update_advertiser_amount
  
  named_scope :created_since, lambda { |date| { :conditions => ["conversions.created_at >= ?", date] } }
  
  def reward_type_string=(string)
    write_attribute(:reward_type, REWARD_TYPES[string])
  end
  
private
  
  def update_publisher_amount
    return true if publisher_amount == 0
    p_id = publisher_app.partner_id
    Partner.connection.execute("SELECT id FROM partners WHERE id = '#{p_id}' FOR UPDATE")
    Partner.connection.execute("UPDATE partners SET pending_earnings = (pending_earnings + #{publisher_amount}) WHERE id = '#{p_id}'")
  end
  
  def update_advertiser_amount
    return true if advertiser_amount == 0 || advertiser_offer.nil?
    p_id = advertiser_offer.partner_id
    Partner.connection.execute("SELECT id FROM partners WHERE id = '#{p_id}' FOR UPDATE")
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{advertiser_amount}) WHERE id = '#{p_id}'")
  end
  
  def sanitize_reward_id
    begin
      UUIDTools::UUID.parse(reward_id) unless reward_id.blank?
    rescue ArgumentError
      self.reward_id = nil
    end
  end
  
end
