class PayoutInfo < ActiveRecord::Base
  include UuidPrimaryKey

  ENCRYPTED_FIELDS = [ :tax_id, :bank_name, :bank_address, :bank_account_number, :bank_routing_number ]
  ACCOUNT_TYPES = %w(Individual Partnership LLC Corporation Other)
  PAYOUT_METHODS = [ ['Check', 'check'], ['ACH', 'ach'], ['Wire', 'wire'], ['PayPal', 'paypal'] ]

  acts_as_decryptable :encrypt => ENCRYPTED_FIELDS, :key => SYMMETRIC_CRYPTO_SECRET, :show => '*' * 8
  belongs_to :partner

  validates_presence_of :partner
  validates_uniqueness_of :partner_id

  validates_format_of :billing_name, :company_name, :with => /^[[:print:]]+$/

  attr_accessor :terms
  validates_acceptance_of :terms
  validates_presence_of :signature, :billing_name, :tax_country, :account_type,
    :tax_id, :company_name, :address_1, :address_city, :address_state, :address_postal_code
  validates_presence_of :bank_name, :bank_account_number, :bank_routing_number, :if => :require_bank_info?
  validates_presence_of :paypal_email, :if => :uses_paypal?
  validates_inclusion_of :account_type, :in => ACCOUNT_TYPES
  validates_inclusion_of :payout_method, :in => PAYOUT_METHODS.map(&:last)
  validates_inclusion_of :payout_method, :in => ['wire'], :if => :international?,
    :message => 'International accounts must use wire transfer'
  validates_each :tax_id do |record, attribute, value|
    id = record.decrypt_tax_id
    unless id.present? && id.length > 4 && id.match(/\d+/)
      record.errors.add(attribute, 'Please enter a valid Tax ID')
    end
  end
  validates_each :beneficiary_name do |record, attribute, value|
    if record.invalid_names?
      record.errors.add(attribute, 'Beneficiary name must match billing name.')
    end
  end

  named_scope :recently_updated, lambda { |date|
    {
      :conditions => [
        "updated_at >= ? AND updated_at < ?",
        date, date + 1.month
      ],
      :include => :partner,
      :order => 'updated_at ASC'
    }
  }

  def decrypted_payment_details
    case payout_method
    when 'check'
      {
        :address_1 => address_1,
        :address_2 => address_2,
        :address_city => address_city,
        :address_state => address_state,
        :address_postal_code => address_postal_code,
        :address_country => address_country.titleize,
      }
    when 'wire', 'ach'
      {
        :bank_name => decrypt_bank_name,
        :bank_address => decrypt_bank_address,
        :bank_account_number => decrypt_bank_account_number,
        :bank_routing_number => decrypt_bank_routing_number,
      }
    when 'paypal'
      {
        :paypal_email => paypal_email
      }
    end.merge({
      :payout_method => payout_method,
      :account_type => account_type,
      :payment_country => payment_country.titleize,
    })
  end

  def invalid_names?
    beneficiary_name.to_s.strip.downcase != billing_name.to_s.strip.downcase
  end

private
  def require_bank_info?
    %w(ach wire).include?(payout_method) || international? && !uses_paypal?
  end

  def international?
    payment_country.to_s.downcase != 'united states of america' && !uses_paypal?
  end

  def uses_paypal?
    payout_method == 'paypal'
  end
end
