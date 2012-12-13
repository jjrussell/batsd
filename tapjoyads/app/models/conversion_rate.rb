class ConversionRate < ActiveRecord::Base
  include UuidPrimaryKey
  include CacheCurrency #This starts a conversion rate immediately by caching the currency

  OVERLAP_ERROR_MESSAGE = I18n.t('text.conversion_rate.error_message')
  CONVERSION_RATE_ERROR_MESSAGE = I18n.t('text.conversion_rate.currency_error_message')

  belongs_to :currency

  validates_presence_of :rate, :minimum_offerwall_bid
  validates_numericality_of :rate, :minimum_offerwall_bid, :greater_than => 0
  validates_uniqueness_of :currency_id, :scope => [:rate]
  validates_uniqueness_of :currency_id, :scope => [:minimum_offerwall_bid]
  validate :necessary_conversion_rate

  def bid_number_to_currency(extended=false)
    divisor = extended ? 50.0 : 100.0
    (minimum_offerwall_bid.to_f / divisor).round(2)
  end

  private

  def necessary_conversion_rate
    currency = Currency.find(self.currency_id)
    return if currency.conversion_rates.blank?
    if currency.conversion_rate >= self.rate
      errors.add(:base, CONVERSION_RATE_ERROR_MESSAGE)
      return
    end
    currency.conversion_rates.each do |conversion_rate|
      if conversion_rate.rate > self.rate && conversion_rate.minimum_offerwall_bid < self.minimum_offerwall_bid
        errors.add(:base, OVERLAP_ERROR_MESSAGE)
        return
      elsif conversion_rate.rate < self.rate && conversion_rate.minimum_offerwall_bid > self.minimum_offerwall_bid
        errors.add(:base, OVERLAP_ERROR_MESSAGE)
        return
      end
    end
  end
end
