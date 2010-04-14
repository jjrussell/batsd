class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.transition_from_crypto_providers = TapjoyCrypto
  end
  
  has_many :role_assignments, :dependent => :destroy
  has_many :user_roles, :through => :role_assignments
  belongs_to :partner
  
  validates_presence_of :partner
  
  def role_symbols
    user_roles.map do |role|
      role.name.underscore.to_sym
    end
  end
  
end
