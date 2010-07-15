class User < ActiveRecord::Base
  include UuidPrimaryKey
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.transition_from_crypto_providers = TapjoyCrypto
  end
  
  has_many :role_assignments
  has_many :partner_assignments
  has_many :user_roles, :through => :role_assignments
  has_many :partners, :through => :partner_assignments
  belongs_to :current_partner, :class_name => 'Partner'
  
  validates_uniqueness_of :username
  
  def role_symbols
    user_roles.map do |role|
      role.name.underscore.to_sym
    end
  end
  
end
