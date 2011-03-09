class PayoutInfo < ActiveRecord::Base
  include UuidPrimaryKey

  ENCRYPTED_FIELDS = [ :tax_id, :bank_name, :bank_address, :bank_account_number, :bank_routing_number ]
  acts_as_decryptable :encrypt => ENCRYPTED_FIELDS, :key => SYMMETRIC_CRYPTO_SECRET, :show => '*' * 8
  belongs_to :partner

  validates_presence_of :partner
  validates_uniqueness_of :partner_id

  def filled?
    billing_name.present? && tax_info_filled? && (bank_info_filled? || us_address_filled?)
  end

private
  def tax_info_filled?
    tax_country.present? &&
      account_type.present? &&
      tax_id.present?
  end

  def bank_info_filled?
    bank_name.present? &&
      bank_account_number.present? &&
      bank_routing_number.present?
  end

  def us_address_filled?
    country = address_country && address_country.downcase
    ['united states', 'united states of america'].include?(country) &&
      company_name.present? &&
      address_1.present? &&
      address_city.present? &&
      address_state.present? &&
      address_postal_code.present?
  end

end
