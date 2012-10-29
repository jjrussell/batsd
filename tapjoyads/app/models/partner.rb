# == Schema Information
#
# Table name: partners
#
#  id                            :string(36)      not null, primary key
#  contact_name                  :string(255)
#  contact_phone                 :string(255)
#  balance                       :integer(4)      default(0), not null
#  pending_earnings              :integer(4)      default(0), not null
#  created_at                    :datetime
#  updated_at                    :datetime
#  payout_frequency              :string(255)     default("monthly"), not null
#  next_payout_amount            :integer(4)      default(0), not null
#  name                          :string(255)
#  calculated_advertiser_tier    :integer(4)
#  calculated_publisher_tier     :integer(4)
#  custom_advertiser_tier        :integer(4)
#  custom_publisher_tier         :integer(4)
#  account_manager_notes         :text
#  disabled_partners             :text            default(""), not null
#  premier_discount              :integer(4)      default(0), not null
#  exclusivity_level_type        :string(255)
#  exclusivity_expires_on        :date
#  transfer_bonus                :decimal(8, 6)   default(0.0), not null
#  rev_share                     :decimal(8, 6)   default(0.5), not null
#  direct_pay_share              :decimal(8, 6)   default(1.0), not null
#  apsalar_username              :string(255)
#  apsalar_api_secret            :string(255)
#  apsalar_url                   :text
#  offer_whitelist               :text            default(""), not null
#  use_whitelist                 :boolean(1)      default(FALSE), not null
#  approved_publisher            :boolean(1)      default(FALSE), not null
#  apsalar_sharing_adv           :boolean(1)      default(FALSE), not null
#  apsalar_sharing_pub           :boolean(1)      default(FALSE), not null
#  reseller_id                   :string(36)
#  billing_email                 :string(255)
#  freshbooks_client_id          :integer(4)
#  accepted_publisher_tos        :boolean(1)
#  sales_rep_id                  :string(36)
#  max_deduction_percentage      :decimal(8, 6)   default(1.0), not null
#  negotiated_rev_share_ends_on  :date
#  accepted_negotiated_tos       :boolean(1)      default(FALSE)
#  cs_contact_email              :string(255)
#  discount_all_offer_types      :boolean(1)      default(FALSE), not null
#  client_id                     :string(36)
#  promoted_offers               :text            default(""), not null
#  payout_threshold              :integer(4)      default(5000000), not null
#  payout_info_confirmation      :boolean(1)      default(FALSE), not null
#  payout_threshold_confirmation :boolean(1)      default(FALSE), not null
#  live_date                     :datetime
#  use_server_whitelist          :boolean(1)      default(FALSE), not null
#  enable_risk_management        :boolean(1)      default(FALSE), not null
#  country                       :string(255)
#

class Partner < ActiveRecord::Base
  include UuidPrimaryKey

  json_set_field :promoted_offers

  BASE_PAYOUT_THRESHOLD = 50_000_00
  APPROVED_INCREASE_PERCENTAGE = 1.2

  has_many :orders
  has_many :payouts
  has_many :currencies
  has_many :partner_assignments
  has_many :users, :through => :partner_assignments
  has_many :apps
  has_many :email_offers
  has_many :rating_offers
  has_many :offerpal_offers
  has_many :generic_offers
  has_many :action_offers
  has_many :video_offers
  has_many :offers
  has_many :coupons
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_partner_id
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_partner_id
  has_many :monthly_accountings
  has_many :offer_discounts, :order => 'expires_on DESC'
  has_many :app_offers, :class_name => 'Offer', :conditions => "item_type = 'App'"
  has_one :payout_info
  belongs_to :sales_rep, :class_name => 'User'
  belongs_to :client
  has_many :earnings_adjustments

  belongs_to :reseller

  validates_presence_of :reseller, :if => Proc.new { |partner| partner.reseller_id? }
  validates_presence_of :client, :if => Proc.new { |partner| partner.client_id? }
  validates_numericality_of :balance, :pending_earnings, :next_payout_amount, :only_integer => true, :allow_nil => false
  validates_numericality_of :premier_discount, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => false
  validates_numericality_of :rev_share, :transfer_bonus, :direct_pay_share, :max_deduction_percentage, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_inclusion_of :exclusivity_level_type, :in => ExclusivityLevel::TYPES, :allow_nil => true, :allow_blank => false
  validates_inclusion_of :use_whitelist, :approved_publisher, :in => [ true, false ]
  validate :exclusivity_level_legal
  validate :sales_rep_is_employee, :if => :sales_rep_id_changed?
  validate :client_id_legal
  validates_format_of :billing_email, :cs_contact_email, :with => Authlogic::Regex.email, :message => "should look like an email address.", :allow_blank => true, :allow_nil => true
  validates_presence_of :name
  validates_each :name do |record, attr, value|
    record.errors.add(attr, "Company Name cannot contain 'Tapjoy'") if value =~ /tap([[:punct:]]|[[:space:]])*joy/iu && !(value =~ /@tapjoy\.com/iu)
  end
  validates_each :disabled_partners, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, "must be blank when using whitelisting") if record.use_whitelist? && value.present?
    if record.disabled_partners_changed?
      value.split(';').each do |partner_id|
        record.errors.add(attribute, "contains an unknown partner id: #{partner_id}") if Partner.find_by_id(partner_id).nil?
      end
    end
  end
  validates_each :offer_whitelist, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, 'must be blank when using blacklisting') if !record.use_whitelist? && value.present?
    if record.offer_whitelist_changed?
      value.split(';').each do |offer_id|
        record.errors.add(attribute, "contains an unknown offer id: #{offer_id}") if Offer.find_by_id(offer_id).nil?
      end
    end
  end
  validates_each :exclusivity_expires_on do |record, attribute, value|
    if record.exclusivity_level_type? && record.exclusivity_expires_on.blank?
      record.errors.add(attribute, "cannot be blank if the Partner has exclusivity_level_type set")
    elsif record.exclusivity_level_type.blank? && record.exclusivity_expires_on?
      record.errors.add(attribute, "must be blank if the Partner does not have exclusivity_level_type set")
    end
  end

  validates_each :negotiated_rev_share_ends_on, :if => :negotiated_rev_share_ends_on_changed?, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, 'You can not choose a date in the past for negotiated rev share expiration time.') if value.to_time < Time.zone.now
  end

  before_validation :remove_whitespace_from_attributes, :update_rev_share
  before_save :check_billing_email
  after_save :update_currencies, :update_offers, :recache_currencies, :recache_offers

  cattr_reader :per_page
  attr_protected :exclusivity_level_type, :exclusivity_expires_on, :premier_discount

  @@per_page = 20

  scope :to_calculate_next_payout_amount, :conditions => ['pending_earnings >= 10000 or pending_earnings > 0 and reseller_id is not ?', nil]
  scope :to_payout, :conditions => 'pending_earnings != 0',
        :order => "#{self.quoted_table_name}.name ASC, #{self.quoted_table_name}.contact_name ASC"
  scope :to_payout_by_earnings, :conditions => 'pending_earnings != 0', :order => 'pending_earnings DESC'
  scope :find_by_name_or_email, lambda { |name_or_email| { :joins => :users,
      :conditions => [ "#{Partner.quoted_table_name}.name LIKE ? OR #{User.quoted_table_name}.email LIKE ?", "%#{name_or_email}%", "%#{name_or_email}%" ] }
    }

  scope :premier, :conditions => 'premier_discount > 0'
  scope :payout_info_changed, lambda { |start_date, end_date| { :joins => :payout_info,
    :conditions => [ "#{PayoutInfo.quoted_table_name}.updated_at >= ? and #{PayoutInfo.quoted_table_name}.updated_at < ? ", start_date, end_date ]
  } }
  scope :with_next_payout, where('next_payout_amount > 0')

  # Searches for partners which have an associated user managing them.
  #
  # @manager_id [Integer, Symbol] filter by the manager's id. Use :none to
  #   find partners without a manager.
  def self.by_manager_id(manager_id)
    if manager_id == :none
      # Find all partners that don't have any admin/account_mgr users associated with them.
      account_mgr = UserRole.find_by_name('account_mgr').id
      admin = UserRole.find_by_name('admin').id
      Partner.joins('join partner_assignments pa on partners.id = pa.partner_id').
              where("pa.partner_id not in (
                      select pa2.partner_id
                      from partner_assignments pa2
                      where pa2.user_id in (
                        select distinct ra4.user_id
                        from role_assignments ra4
                        where ra4.user_role_id in (?, ?)
                      )
                    )", account_mgr, admin)
    else
      Partner.joins(:users).where('users.id = ?', manager_id)
    end
  end

  # Searches partners
  #
  # @user_id [Integer, nil] filter by user id.
  # @manager [Integer, Symbol, nil] filter by the manager's id. Use :none to
  #   find partners without a manager.
  # @country [String, nil] filter by the name of a country.
  # @query [String, nil] filter by part (or all) of a name or email.
  def self.search(user_id, manager_id, country, query)
    if manager_id
      result = Partner.by_manager_id(manager_id)
    else
      result = Partner.scoped(:order => 'partners.created_at DESC', :include => [ :offers, :users ])
    end
    result = result.joins(:users).where('users.id = ?', user_id) if user_id
    result = result.scoped_by_country(country) if country
    result = result.find_by_name_or_email(query) if query
    result
  end

  def applied_offer_discounts
    offer_discounts.select { |discount| discount.active? && discount.amount == premier_discount }
  end

  def discount_expires_on
    active_offer_discount = applied_offer_discounts.max { |a,b| a.expires_on <=> b.expires_on }
    active_offer_discount ? active_offer_discount.expires_on : nil
  end

  def self.calculate_next_payout_amount(partner_id)
    Partner.using_slave_db do
      Partner.slave_connection.execute("BEGIN")
      partner = Partner.find(partner_id)
      return partner.pending_earnings - partner.publisher_conversions.created_since(partner.payout_cutoff_date).sum(:publisher_amount)
    end
  ensure
    Partner.using_slave_db do
      Partner.slave_connection.execute("COMMIT")
    end
  end

  def self.verify_balances(partner_id, alert_on_mismatch = false)
    Partner.using_slave_db do
      Partner.slave_connection.execute("BEGIN")
      partner = Partner.find(partner_id)
      partner.recalculate_balance_and_pending_earnings
      if alert_on_mismatch
        if partner.balance_changed?
          Notifier.alert_new_relic(BalancesMismatch, "Balance mismatch for partner: #{partner.id}, previously: #{partner.balance_was}, now: #{partner.balance}")
        end
        if partner.pending_earnings_changed?
          Notifier.alert_new_relic(BalancesMismatch, "Pending Earnings mismatch for partner: #{partner.id}, previously: #{partner.pending_earnings_was}, now: #{partner.pending_earnings}")
        end
      end
      return partner
    end
  ensure
    Partner.using_slave_db do
      Partner.slave_connection.execute("COMMIT")
    end
  end

  def is_premier?
    offer_discounts.active.present?
  end

  def account_managers=(managers=[])
    # replace
    users.delete(account_managers)
    users << managers
  end

  def account_managers
    users.select{|user| user.can_manage_account?}
  end

  def non_managers
    users.reject{|user| user.can_manage_account?}
  end

  def remove_user(user)
    if users.include?(user)
      handle_last_user! if users.length == 1
      user.partners.delete(self)
      if user.reseller_id?
        self.reseller_id = nil
        save!
      end
      user.clean_up_current_partner(self)
    end
  end

  def handle_last_user!
    users << User.userless_partner_holder
  end

  def get_disabled_partner_ids
    Set.new(disabled_partners.split(';'))
  end

  def get_disabled_partners
    Partner.find_all_by_id(disabled_partners.split(';'))
  end

  def get_offer_whitelist
    Set.new(offer_whitelist.split(';'))
  end

  def add_to_whitelist(offer_id)
    unless offer_id.blank?
      self.offer_whitelist = offer_whitelist.split(';').push(offer_id).uniq.join(';')
    end
  end

  def remove_from_whitelist(offer_id)
    unless offer_whitelist.blank? && offer_id.blank?
      self.offer_whitelist = offer_whitelist.split(';').reject { |offer| offer == offer_id}.join(';')
    end
  end

  def payout_cutoff_date(reference_date = nil)
    reference_date ||= Time.zone.now
    reference_date -= 3.days
    case payout_frequency
    when 'semimonthly'
      reference_date.day > 15 ? (reference_date.beginning_of_month + 15.days) : reference_date.beginning_of_month
    else
      reference_date.beginning_of_month
    end
  end

  def leftover_payout_amount
    pending_earnings - next_payout_amount
  end

  def make_payout(amount)
    cutoff_date = self.payout_cutoff_date - 1.day
    amount = (amount.to_f * 100).round
    payout = self.payouts.create!(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    calculate_payout_threshold(amount)
    payout
  end

  def calculate_payout_threshold(amount)
    threshold = amount * Partner::APPROVED_INCREASE_PERCENTAGE
    self.payout_threshold = [threshold, Partner::BASE_PAYOUT_THRESHOLD].max
    self.save
  end

  def reset_balances
    Partner.transaction do
      reload(:lock => 'FOR UPDATE')
      recalculate_balance_and_pending_earnings
      save!
    end
  end

  def build_recoupable_marketing_credit(amount, internal_notes)
    build_generic_transfer(amount, 4, internal_notes)
  end

  def build_transfer(amount, internal_notes)
    records = build_generic_transfer(amount, 3, internal_notes)
    marketing_amount = (amount * transfer_bonus).to_i
    records << orders.build(:amount => marketing_amount, :status => 1, :payment_method => 5, :note => internal_notes) unless marketing_amount == 0
    records
  end

  # This method will most likely not produce accurate sums unless
  # called from within some sort of transaction. See reset_balances
  # and Partner.verify_balances for examples.
  def recalculate_balance_and_pending_earnings
    accounting_cutoff = Conversion.accounting_cutoff_time

    publisher_conversions_sum = monthly_accountings.prior_to(accounting_cutoff).sum(:earnings)
    publisher_conversions_sum += publisher_conversions.created_since(accounting_cutoff).sum(:publisher_amount)

    advertiser_conversions_sum = monthly_accountings.prior_to(accounting_cutoff).sum(:spend)
    advertiser_conversions_sum += advertiser_conversions.created_since(accounting_cutoff).sum(:advertiser_amount)

    orders_sum = orders.sum(:amount)
    payouts_sum = payouts.sum(:amount, :conditions => 'status = 1')
    earnings_adjustments_sum = earnings_adjustments.sum(:amount)

    self.balance = orders_sum + advertiser_conversions_sum
    self.pending_earnings = publisher_conversions_sum - payouts_sum + earnings_adjustments_sum
  end

  def name_or_contact_name
    name.present? ? name : contact_name
  end

  def has_publisher_offer?
    offers.any?{|offer| offer.is_publisher_offer?}
  end

  def exclusivity_level
    exclusivity_level_type? ? exclusivity_level_type.constantize.new : nil
  end

  def set_exclusivity_level!(new_exclusivity_level_name)
    new_exclusivity_level_name = new_exclusivity_level_name.to_s
    if ExclusivityLevel::TYPES.include?(new_exclusivity_level_name)
      new_exclusivity_level = new_exclusivity_level_name.constantize.new
      self.exclusivity_level_type = new_exclusivity_level_name
      self.exclusivity_expires_on = Date.today + new_exclusivity_level.months.months
      if self.save
        OfferDiscount.create!(:partner => self, :source => 'Exclusivity', :amount => exclusivity_level.discount, :expires_on => exclusivity_expires_on)
        true
      else
        false
      end
    else
      raise InvalidExclusivityLevelError.new("#{new_exclusivity_level_name} is not a valid exclusivity level.")
    end
  end

  def expire_exclusivity_level
    self.exclusivity_level_type = nil
    self.exclusivity_expires_on = nil
  end

  def expire_exclusivity_level!
    expire_exclusivity_level
    save!
  end

  def recalculate_premier_discount
    self.premier_discount = offer_discounts.active.collect(&:amount).max || 0
  end

  def recalculate_premier_discount!
    recalculate_premier_discount
    save!
  end

  def needs_exclusivity_expired?
    exclusivity_expires_on && exclusivity_expires_on <= Date.today
  end

  def completed_payout_info?
    payout_info.present? && payout_info.valid?
  end

  def tapjoy_sponsored?
    offers.blank? ? false : offers.all?(&:tapjoy_sponsored?)
  end

  def set_tapjoy_sponsored_on_offers!(flag)
    offers.each do |offer|
      offer.tapjoy_sponsored = flag
      offer.save! if offer.changed?
    end
  end

  def offers_for_promotion
    available_offers = { :android => [], :iphone => [], :windows => [] }
    self.offers.each do |offer|
      platform = offer.promotion_platform
      available_offers[platform].push(offer) if platform.present? && offer.can_be_promoted?
    end
    available_offers
  end

  def update_promoted_offers(offer_ids)
    self.promoted_offers = offer_ids.sort
    changed? ? save : true
  end

  # For use within TJM (since dashboard URL helpers aren't available within TJM)
  def dashboard_partner_url
    uri = URI.parse(DASHBOARD_URL)
    "#{uri.scheme}://#{uri.host}/partners/#{self.id}"
  end

  def confirmation_notes
    notes = []
    notes << payout_threshold_notes unless self.payout_threshold_confirmation
    notes << payout_info_notes unless self.payout_info_confirmation
    notes << 'Payout Info not Present!' unless self.completed_payout_info?
    notes
  end

  def confirmed_for_payout?
    self.payout_info_confirmation && self.payout_threshold_confirmation
  end

  def confirm_for_payout(user)
    self.payout_info_confirmation = true  if can_confirm_payout_info?(user)
    if can_confirm_payout_threshold?(user)
      self.payout_threshold_confirmation = true
      self.payout_threshold *= 1.1
    end
  end

  def monthly_accounting(year, month)
    MonthlyAccounting.using_slave_db do
      conditions = [ "partner_id = ? AND year = ? AND month = ?", self.id, year, month ]
      monthly_accounting = MonthlyAccounting.find(:all, :conditions => conditions).first
    end
  end

  def account_manager_email
    @account_manager_email ||= self.account_managers.present? ? self.account_managers.first.email.downcase : "\xFF"
  end


  def can_confirm_payout_info?(user)
    user_roles = user.role_assignments.map { |x| x.name}
    (payout_info_confirmation_roles & user_roles).present?
  end

  def can_confirm_payout_threshold?(user)
    user_roles = user.role_assignments.map { |x| x.name}
    (payout_threshold_confirmation_roles & user_roles).present?
  end

  def can_be_confirmed?(user)
    ( !self.payout_info_confirmation && can_confirm_payout_info?(user)) ||
        ( !self.payout_threshold_confirmation && can_confirm_payout_threshold?(user))
  end

  def build_dev_credit(amount, internal_notes)
    payouts.build(:amount => amount, :month => Time.zone.now.month,
        :year => Time.zone.now.year, :payment_method => 6 )
  end

  private

  def update_currencies
    if rev_share_changed? || direct_pay_share_changed? || disabled_partners_changed? || offer_whitelist_changed? || use_whitelist_changed? || accepted_publisher_tos_changed? || max_deduction_percentage_changed? || reseller_id_changed?
      currencies.each do |c|
        c.set_values_from_partner_and_reseller
        c.save!
      end
    end
  end

  def update_offers
    return true unless (premier_discount_changed? || reseller_id_changed? || discount_all_offer_types_changed?)
    if premier_discount_changed? || discount_all_offer_types_changed?
      offers.each { |o| o.update_payment(true) }
    end
    if reseller_id_changed?
      offers.each(&:set_reseller_from_partner)
    end
    offers.each(&:save!)
  end

  def recache_currencies
    currencies.each { |c| c.cache }
  end

  def recache_offers
    clear_association_cache
    offers.each { |o| o.cache }
  end

  def update_rev_share
    self.rev_share = reseller.rev_share if reseller_id_changed? && reseller_id?
  end

  def exclusivity_level_legal
    old_exclusivity_level = exclusivity_level_type_was.present? ? exclusivity_level_type_was.constantize.new : nil

    if old_exclusivity_level && exclusivity_level && old_exclusivity_level.months > exclusivity_level.months
      errors.add :exclusivity_level_type, "is illegal for a Partner with a current exclusivity level of #{exclusivity_level_type}"
    end
  end

  def remove_whitespace_from_attributes
    self.disabled_partners = disabled_partners.gsub(/\s/, '')
    self.offer_whitelist   = offer_whitelist.gsub(/\s/, '')
  end

  def check_billing_email
    self.freshbooks_client_id = nil if billing_email_changed?
  end

  def sales_rep_is_employee
    if sales_rep && !sales_rep.employee?
      errors.add(:sales_rep, 'must be an employee')
    end
  end

  def build_generic_transfer(amount, payment_method, internal_notes)
    records = []
    records << payouts.build(:amount => amount, :month => Time.zone.now.month, :year => Time.zone.now.year, :payment_method => payment_method)
    records << orders.build(:amount => amount, :status => 1, :payment_method => payment_method, :note => internal_notes)
    records
  end

  def client_id_legal
    errors.add :client_id, "cannot be switched to another client." if client_id_changed? && client_id_was.present? && client_id.present?
  end

  def payout_threshold_notes
    "SYSTEM: Payout is greater than or equal to #{NumberHelper.number_to_currency((self.payout_threshold / 100).to_f)}"
  end

  def payout_info_notes
    'SYSTEM: Partner Payout Information has changed.'
  end

  def payout_info_confirmation_roles
    %w(payout_manager)
  end

  def payout_threshold_confirmation_roles
    %w(payout_manager account_mgr admin)
  end
end
