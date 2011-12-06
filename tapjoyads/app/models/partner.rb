class Partner < ActiveRecord::Base
  include UuidPrimaryKey

  THE_REAL_TAPJOY_PARTNER_ID = "70f54c6d-f078-426c-8113-d6e43ac06c6d"

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
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_partner_id
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_partner_id
  has_many :monthly_accountings
  has_many :offer_discounts, :order => 'expires_on DESC'
  has_many :app_offers, :class_name => 'Offer', :conditions => "item_type = 'App'"
  has_one :payout_info
  belongs_to :sales_rep, :class_name => 'User'
  has_many :earnings_adjustments

  belongs_to :reseller

  validates_presence_of :reseller, :if => Proc.new { |partner| partner.reseller_id? }
  validates_numericality_of :balance, :pending_earnings, :next_payout_amount, :only_integer => true, :allow_nil => false
  validates_numericality_of :premier_discount, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => false
  validates_numericality_of :rev_share, :transfer_bonus, :direct_pay_share, :max_deduction_percentage, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_inclusion_of :exclusivity_level_type, :in => ExclusivityLevel::TYPES, :allow_nil => true, :allow_blank => false
  validates_inclusion_of :use_whitelist, :approved_publisher, :in => [ true, false ]
  validate :exclusivity_level_legal
  validate :sales_rep_is_employee, :if => :sales_rep_id_changed?
  validates_format_of :billing_email, :cs_contact_email, :with => Authlogic::Regex.email, :message => "should look like an email address.", :allow_blank => true, :allow_nil => true
  # validates_format_of :name, :with => /^[[:print:]]*$/, :message => "Partner name must be alphanumeric."
  validates_each :disabled_partners, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, "must be blank when using whitelisting") if record.use_whitelist? && value.present?
    if record.disabled_partners_changed?
      value.split(';').each do |partner_id|
        record.errors.add(attribute, "contains an unknown partner id: #{partner_id}") if Partner.find_by_id(partner_id).nil?
      end
    end
  end
  validates_each :offer_whitelist, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, "must be blank when using blacklisting") if !record.use_whitelist? && value.present?
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
  after_save :update_currencies, :update_offers

  cattr_reader :per_page
  attr_protected :exclusivity_level_type, :exclusivity_expires_on, :premier_discount

  @@per_page = 20

  named_scope :to_calculate_next_payout_amount, :conditions => 'pending_earnings >= 10000'
  named_scope :to_payout, :conditions => 'pending_earnings != 0', :order => 'name ASC, contact_name ASC'
  named_scope :to_payout_by_earnings, :conditions => 'pending_earnings != 0', :order => 'pending_earnings DESC'
  named_scope :search, lambda { |name_or_email| { :joins => :users,
      :conditions => [ "#{Partner.quoted_table_name}.name LIKE ? OR #{User.quoted_table_name}.email LIKE ?", "%#{name_or_email}%", "%#{name_or_email}%" ] }
    }
  named_scope :premier, :conditions => 'premier_discount > 0'
  named_scope :payout_info_changed, lambda { |start_date, end_date| { :joins => :payout_info,
    :conditions => [ "#{PayoutInfo.quoted_table_name}.updated_at >= ? and #{PayoutInfo.quoted_table_name}.updated_at < ? ", start_date, end_date ]
  } }

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
      return partner.pending_earnings - Conversion.created_since(partner.payout_cutoff_date).sum(:publisher_amount, :conditions => [ "publisher_app_id IN (?)", partner.app_ids ])
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
    if users.length > 1 && users.include?(user)
      user.partners.delete(self)
      if user.reseller_id?
        self.reseller_id = nil
        save!
      end
      if user.partners.blank?
        user.current_partner = Partner.new(:name => user.email, :contact_name => user.email)
        user.partners << user.current_partner
        user.save
      elsif user.current_partner_id == id
        user.current_partner = user.partners.first
        user.save
      else
        true
      end
    end
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

  def reset_balances
    Partner.transaction do
      reload(:lock => 'FOR UPDATE')
      recalculate_balance_and_pending_earnings
      save!
    end
  end

  def build_transfer(amount)
    records = []
    records << payouts.build(:amount => amount, :month => Time.zone.now.month, :year => Time.zone.now.year, :payment_method => 3)
    records << orders.build(:amount => amount, :status => 1, :payment_method => 3)
    marketing_amount = (amount * transfer_bonus).to_i
    records << orders.build(:amount => marketing_amount, :status => 1, :payment_method => 2) unless marketing_amount == 0
    records
  end

  # This method will most likely not produce accurate sums unless
  # called from within some sort of transaction. See reset_balances
  # and Partner.verify_balances for examples.
  def recalculate_balance_and_pending_earnings
    accounting_cutoff = Conversion.accounting_cutoff_time

    publisher_conversions_sum = monthly_accountings.prior_to(accounting_cutoff).sum(:earnings)
    publisher_conversions_sum += Conversion.created_since(accounting_cutoff).sum(:publisher_amount, :conditions => [ "publisher_app_id IN (?)", app_ids ])

    advertiser_conversions_sum = monthly_accountings.prior_to(accounting_cutoff).sum(:spend)
    advertiser_conversions_sum += Conversion.created_since(accounting_cutoff).sum(:advertiser_amount, :conditions => [ "advertiser_offer_id IN (?)", offer_ids ])

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

  def tapjoy_sponsored(flag)
    offers.each do |offer|
      offer.tapjoy_sponsored = flag
      offer.save! if offer.changed?
    end
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
    return true if !(premier_discount_changed? || reseller_id_changed?)
    if premier_discount_changed?
      offers.each { |o| o.update_payment(true) }
    end
    if reseller_id_changed?
      offers.each(&:set_reseller_from_partner)
    end
    offers.each(&:save!)
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
end
