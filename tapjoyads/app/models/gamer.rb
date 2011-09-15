class Gamer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :gamer_devices
  
  attr_accessor :terms_of_service, :current_device_id
  validates_acceptance_of :terms_of_service, :on => :create
  
  before_create :generate_confirmation_token
  
  alias_method :devices, :gamer_devices
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.perishable_token_valid_for = 1.hour
    c.login_field = :email
    c.validate_login_field = false
    c.require_password_confirmation = false
  end
  
  def confirm!
    self.confirmed_at = Time.zone.now
    save
  end
  
private

  def generate_confirmation_token
    self.confirmation_token = Authlogic::Random.friendly_token
  end
end
