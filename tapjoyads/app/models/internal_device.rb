class InternalDevice < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :user

  STATUSES = [ 'pending', 'approved', 'blocked' ]

  attr_accessible :description, :verifier
  attr_reader :verifier

  before_validation_on_create :generate_verification_key, :set_status

  validates_inclusion_of :status, :in => STATUSES
  validates_presence_of :verification_key

  named_scope :approved, :conditions => "status = 'approved'"

  def generate_verification_key
    self.verification_key ||= (0..7).map{ rand(9) + 1 }.join.to_i
  end

  def set_status
    self.status ||= 'pending'
  end

  def block!
    self.status = 'blocked'
    self.save
  end

  def verifier=(ver)
    self.status = 'approved' if verification_key == ver.to_i
  end

  def pending?; status == 'pending'; end
  def approved?; status == 'approved'; end
  def blocked?; status == 'blocked'; end

end
