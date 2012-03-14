class User < ActiveRecord::Base
  include UuidPrimaryKey

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.transition_from_crypto_providers = TapjoyCrypto
    c.perishable_token_valid_for = 1.hour
    c.merge_validates_uniqueness_of_login_field_options(:case_sensitive => true)
    c.merge_validates_uniqueness_of_email_field_options(:case_sensitive => true)
  end

  has_many :role_assignments, :dependent => :destroy
  has_many :partner_assignments, :dependent => :destroy
  has_many :user_roles, :through => :role_assignments
  has_many :partners, :through => :partner_assignments
  has_many :enable_offer_requests
  has_many :admin_devices
  has_many :internal_devices
  has_many :partners_for_sales, :class_name => 'Partner', :foreign_key => 'sales_rep_id'
  belongs_to :current_partner, :class_name => 'Partner'
  belongs_to :reseller

  has_one :employee, :primary_key => :email, :foreign_key => :email

  attr_accessor :terms_of_service
  validates_acceptance_of :terms_of_service, :on => :create
  validates_presence_of :reseller, :if => Proc.new { |user| user.reseller_id? }

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
    users = User.find(:all, :joins => [:role_assignments],
                      :conditions => conditions, :order => 'email')
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

  def after_approve(approval)
    ApprovalMailer.deliver_approved(email, :user, :subject => 'Your account has been approved on Tapjoy!')
  end

  def after_reject(approval)
    ApprovalMailer.deliver_rejected(email, :user, :subject => 'Your account has been rejected on Tapjoy!', :reason => approval.reason)
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
