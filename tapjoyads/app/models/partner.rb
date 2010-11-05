class Partner < ActiveRecord::Base
  include UuidPrimaryKey
  
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
  has_many :offers
  has_many :publisher_conversions, :through => :apps
  has_many :advertiser_conversions, :through => :offers
  has_many :monthly_accountings
  has_many :offer_discounts, :order => 'expires_on DESC'
  has_many :app_offers, :class_name => 'Offer', :conditions => "item_type = 'App'"
  
  validates_numericality_of :balance, :pending_earnings, :next_payout_amount, :only_integer => true, :allow_nil => false
  validates_numericality_of :premier_discount, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => false
  validates_inclusion_of :exclusivity_level_type, :in => ExclusivityLevel::TYPES, :allow_nil => true, :allow_blank => false
  validate :exclusivity_level_legal
  validates_each :disabled_partners, :allow_blank => true do |record, attribute, value|
    if record.disabled_partners_changed?
      value.split(';').each do |partner_id|
        record.errors.add(attribute, "contains an unknown partner id: #{partner_id}") if Partner.find_by_id(partner_id).nil?
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
  
  after_create :create_mail_chimp_entry
  after_save :update_currencies, :update_app_offers
  
  cattr_reader :per_page
  attr_protected :exclusivity_level_type, :exclusivity_expires_on, :premier_discount
  
  @@per_page = 20
  
  named_scope :to_calculate_next_payout_amount, :conditions => 'pending_earnings >= 10000'
  named_scope :to_payout, :conditions => 'pending_earnings != 0'
  named_scope :search, lambda { |name_or_email| { :joins => :users,
      :conditions => [ "partners.name LIKE ? OR users.email LIKE ?", "%#{name_or_email}%", "%#{name_or_email}%" ] }
    }

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

  def get_disabled_partner_ids
    Set.new(disabled_partners.split(';'))
  end
  
  def get_disabled_partners
    Partner.find_all_by_id(disabled_partners.split(';'))
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
  
  # This method will most likely not produce accurate sums unless
  # called from within some sort of transaction. See reset_balances
  # and Partner.verify_balances for examples.
  def recalculate_balance_and_pending_earnings
    orders_sum = orders.sum(:amount, :conditions => 'status = 1')
    payouts_sum = payouts.sum(:amount, :conditions => 'status = 1')
    publisher_conversions_sum = Conversion.sum(:publisher_amount, :conditions => [ "publisher_app_id IN (?)", app_ids ])
    advertiser_conversions_sum = Conversion.sum(:advertiser_amount, :conditions => [ "advertiser_offer_id IN (?)", offer_ids ])
    self.balance = orders_sum + advertiser_conversions_sum
    self.pending_earnings = publisher_conversions_sum - payouts_sum
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
  
private

  def create_mail_chimp_entry
    message = { :type => "create", :partner_id => self.id }.to_json
    Sqs.send_message(QueueNames::MAIL_CHIMP_UPDATES, message)
  end
  
  def update_currencies
    if installs_money_share_changed? || disabled_partners_changed?
      currencies.each do |c|
        c.set_values_from_partner
        c.save!
      end
    end
  end
  
  def update_app_offers
    if premier_discount_changed?
      app_offers.each(&:update_payment!)
    end
  end
  
  def exclusivity_level_legal
    old_exclusivity_level = exclusivity_level_type_was.present? ? exclusivity_level_type_was.constantize.new : nil
    
    if old_exclusivity_level && exclusivity_level && old_exclusivity_level.months > exclusivity_level.months
      errors.add :exclusivity_level_type, "is illegal for a Partner with a current exclusivity level of #{exclusivity_level_type}"
    end
  end
  
end
