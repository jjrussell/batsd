class InternalDevice < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :user

  STATUS_CODES = {
    0 => 'pending',
    1 => 'approved',
    2 => 'blocked',
  }

  attr_accessible :description, :verifier
  attr_reader :verifier

  before_validation_on_create :generate_verification_key, :set_status

  validates_inclusion_of :status_id, :in => STATUS_CODES.keys
  validates_presence_of :verification_key

  named_scope :approved, :conditions => 'status_id = 1'

  def status
    STATUS_CODES[status_id]
  end

  def status=(string)
    raise "invalid status" unless STATUS_CODES.values.include?(string)
    self.status_id = STATUS_CODES.invert[string]
  end

  def generate_verification_key
    self.verification_key ||= rand(1000000)
  end

  def set_status
    self.status ||= 'pending'
  end

  def block!
    self.status = 'blocked'
    self.save
  end

  def verifier=(ver)
    self.status = verification_key == ver.to_i ? 'approved' : 'blocked'
  end

  def pending?; status == 'pending'; end
  def approved?; status == 'approved'; end
  def blocked?; status == 'blocked'; end

end
