class Gamer < ActiveRecord::Base
  include UuidPrimaryKey
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.perishable_token_valid_for = 1.hour
    c.merge_validates_length_of_email_field_options({ :allow_blank => true, :allow_nil => false })
    c.merge_validates_format_of_email_field_options({ :allow_blank => true, :allow_nil => false })
    c.validates_uniqueness_of_email_field_options({ :if => Proc.new { false } })
  end
  
end
