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

  def reward_type_string=(string)
    self.write_attribute(:reward_type, REWARD_TYPES[string])
  end

private

  def sanitize_reward_id
    begin
      UUIDTools::UUID.parse(reward_id) unless reward_id.blank?
    rescue ArgumentError
      self.reward_id = nil
    end
  end

end
