class Gamer < ActiveRecord::Base
  include UuidPrimaryKey
  
  acts_as_authentic do |c|
    c.login_field = :email
    c.validate_login_field = false
    c.merge_validates_length_of_password_field_options(:minimum => 8)
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.perishable_token_valid_for = 1.hour
  end
  
end
