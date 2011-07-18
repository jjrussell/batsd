  class Gamer < ActiveRecord::Base
  include UuidPrimaryKey
  
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
  
end
