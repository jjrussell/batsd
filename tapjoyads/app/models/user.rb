class User < ActiveRecord::Base
  include UuidPrimaryKey

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.transition_from_crypto_providers = TapjoyCrypto
    c.perishable_token_valid_for = 1.hour
  end

  has_many :role_assignments, :dependent => :destroy
  has_many :partner_assignments, :dependent => :destroy
  has_many :user_roles, :through => :role_assignments
  has_many :partners, :through => :partner_assignments
  belongs_to :current_partner, :class_name => 'Partner'

  attr_accessor :terms_of_service
  validates_acceptance_of :terms_of_service, :on => :create

  def role_symbols
    user_roles.map do |role|
      role.name.underscore.to_sym
    end << :partner
  end

  def is_one_of?(array)
    (role_symbols & array).present?
  end

  def can_manage_account?
    self.is_one_of?([:agency, :account_mgr])
  end

  def managing?(partner)
    self.can_manage_account? && partner.users.include?(self)
  end

  def self.account_managers
    Mc.get_and_put('account_managers', false, 1.day) do
      RoleAssignment.find_all_by_user_role_id(UserRole.find_by_name("account_mgr")).map(&:user).sort_by(&:email)
    end
  end
end
