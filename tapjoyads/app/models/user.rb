# == Schema Information
#
# Table name: users
#
#  id                      :string(36)      not null, primary key
#  username                :string(255)     not null
#  email                   :string(255)
#  crypted_password        :string(255)
#  password_salt           :string(255)
#  persistence_token       :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  current_partner_id      :string(36)
#  perishable_token        :string(255)     default(""), not null
#  current_login_at        :datetime
#  last_login_at           :datetime
#  time_zone               :string(255)     default("UTC"), not null
#  can_email               :boolean(1)      default(TRUE)
#  receive_campaign_emails :boolean(1)      default(TRUE), not null
#  api_key                 :string(255)     not null
#  auth_net_cim_id         :string(255)
#  reseller_id             :string(36)
#  state                   :string(255)
#  country                 :string(255)
#  account_type            :string(255)
#

class User < ActiveRecord::Base
  include UuidPrimaryKey

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.transition_from_crypto_providers = TapjoyCrypto
    c.perishable_token_valid_for = 1.hour
    c.merge_validates_uniqueness_of_login_field_options(:case_sensitive => true)
    c.merge_validates_uniqueness_of_email_field_options(:case_sensitive => true)
  end

  USERLESS_PARTNER_USER_ID = '65dc766a-d05f-45b4-9fca-1f81e3aed2d6'

  has_many :role_assignments, :dependent => :destroy
  has_many :partner_assignments, :dependent => :destroy
  has_many :user_roles, :through => :role_assignments
  has_many :partners, :through => :partner_assignments, :readonly => false
  has_many :enable_offer_requests, :foreign_key => 'requested_by_id'
  has_many :enable_offer_assignments, :class_name => 'EnableOfferRequest', :foreign_key => 'assigned_to_id'
  has_many :admin_devices
  has_many :internal_devices
  has_many :partners_for_sales, :class_name => 'Partner', :foreign_key => 'sales_rep_id'
  belongs_to :current_partner, :class_name => 'Partner'
  belongs_to :reseller

  has_one :employee, :primary_key => :email, :foreign_key => :email

  attr_accessor :terms_of_service
  validates_acceptance_of :terms_of_service, :on => :create
  validates_presence_of :reseller, :if => Proc.new { |user| user.reseller_id? }
  validates_presence_of :country, :on => :create,
    :message => 'Please select a country'

  scope :internal_users, {
    :conditions => [ "( email LIKE ? OR email LIKE ? ) AND email NOT LIKE ?", "%@tapjoy.com", "%offerpal.com", "%+%" ],
    :include => [ :role_assignments, :user_roles ]
  }
  scope :external_users_with_roles, {
    :joins => [ :user_roles ],
    :include => [ :role_assignments, :user_roles ],
    :conditions => [ 'user_roles.name != ? AND email NOT LIKE ? AND email NOT LIKE ?', 'agency', "%@tapjoy.com", "%offerpal.com" ],
  }

  serialize :account_type, Array

  before_create :regenerate_api_key
  after_create :create_mail_chimp_entry
  after_save :update_auth_net_cim_profile

  def role_symbols
    user_roles.map do |role|
      role.name.underscore.to_sym
    end << :partner
  end

  def is_one_of?(array)
    (role_symbols & array).present?
  end

  def can_manage_account?
    self.is_one_of?([:account_mgr, :admin])
  end

  def managing?(partner)
    self.can_manage_account? && partner.users.include?(self)
  end

  def regenerate_api_key
    self.api_key = UUIDTools::UUID.random_create.hexdigest
  end

  def self.account_managers
    role = UserRole.find_by_name("account_mgr")
    conditions = [ "#{RoleAssignment.quoted_table_name}.user_role_id = ?", role.id]
    users = User.joins(:role_assignments).where(conditions).order(:email)
  end

  def self.sales_reps
    account_managers
  end

  def has_valid_email?
    email.present? && !(/mailinator\.com$|example\.com$|test\.com$/ =~ email)
  end

  def employee?
    user_roles.any? { |role| role.employee? }
  end

  def to_s
    email
  end

  # Make sure nil comes back as an empty array
  def account_type
    (super || [])
  end

  def clean_up_current_partner(old_partner)
    if partners.blank?
      partners << Partner.new(:name => email, :contact_name => email)
      save
    elsif current_partner_id == old_partner.id
      self.current_partner = partners.first
      save
    else
      true
    end
  end

  private

  def update_auth_net_cim_profile
    if auth_net_cim_id.present? && (email_changed? || id_changed?)
      Billing.update_customer_profile(self)
    end
  end

  def create_mail_chimp_entry
    return if Rails.env.test?
    if has_valid_email?
      message = { :type => "add_user", :user_id => id }.to_json
      Sqs.send_message(QueueNames::MAIL_CHIMP_UPDATES, message)
    end
  end

end
