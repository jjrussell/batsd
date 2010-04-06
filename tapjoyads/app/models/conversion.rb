class Conversion < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :publisher_app_id
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :reward_type, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => [ 0, 1, 2 ]

  before_save :sanitize_reward_id

private

  def sanitize_reward_id
    begin
      UUIDTools::UUID.parse(reward_id) unless reward_id.blank?
    rescue ArgumentError
      self.reward_id = nil
    end
  end

end
