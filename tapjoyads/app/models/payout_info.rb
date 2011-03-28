class PayoutInfo < ActiveRecord::Base
  include UuidPrimaryKey

  ENCRYPTED_FIELDS = [ :tax_id, :bank_name, :bank_address, :bank_account_number, :bank_routing_number ]
  acts_as_decryptable :encrypt => ENCRYPTED_FIELDS, :key => SYMMETRIC_CRYPTO_SECRET, :show => '*' * 8
  belongs_to :partner

  validates_presence_of :partner
  validates_uniqueness_of :partner_id

  named_scope :recently_updated, {
    :conditions => [
      "updated_at < ? AND updated_at >= ?",
      Time.now.beginning_of_month,
      Time.now.beginning_of_month - 1.month
    ],
    :order => 'updated_at ASC'
  }

  def filled?
    billing_name.present? && tax_info_filled? && payout_info_filled?
  end

private
  def tax_info_filled?
    tax_country.present? &&
      account_type.present? &&
      tax_id.present?
  end

  def payout_info_filled?
    country = address_country && address_country.downcase
    if ['united states', 'united states of america'].include?(country) && payout_method == 'check'
      address_filled?
    else
      bank_info_filled?
    end
  end

  def bank_info_filled?
    bank_name.present? &&
      bank_account_number.present? &&
      bank_routing_number.present?
  end

  def address_filled?
    company_name.present? &&
    address_1.present? &&
    address_city.present? &&
    address_state.present? &&
    address_postal_code.present?
  end

end
