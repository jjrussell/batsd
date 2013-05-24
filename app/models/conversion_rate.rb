class ConversionRate < ActiveRecord::Base
  include UuidPrimaryKey
  include CacheCurrency #This starts a conversion rate immediately by caching the currency

  belongs_to :currency

  validates :rate,                  :presence => true, :numericality => { :greater_than => 0 }
  validates :minimum_offerwall_bid, :presence => true, :numericality => { :greater_than => 0 }
  validates :currency_id,           :uniqueness => { :scope => [:rate] }
  validates :currency_id,           :uniqueness => { :scope => [:minimum_offerwall_bid] }
  validate :necessary_conversion_rate

  def bid_number_to_currency(extended=false)
    extended ? calculated_min_bid(50.0) : calculated_min_bid(100.0)
  end

  def calculated_min_bid(val)
    (minimum_offerwall_bid.to_f / val).round(2)
  end

  private

  def necessary_conversion_rate
    return if self.errors.present? #no need to continue searching for errors if already present
    overlap_error_message         = "Unable to create conversion rate, you are trying to add a conversion rate and
                                     minimum offer bid that overlaps already created conversion rates."
    conversion_rate_error_message = "Unable to create conversion rate, you are trying to create a conversion rate
                                     with a conversion rate value less than or equal to the currency's conversion rate."
    errors.add(:base, conversion_rate_error_message) and return if invalid_rate?
    currency.conversion_rates.each do |conversion_rate|
      next if conversion_rate == self
      errors.add(:base, overlap_error_message) and return if outside_bounds?(conversion_rate) || inside_bounds?(conversion_rate)
    end
  end

  def invalid_rate?
    self.currency.conversion_rate >= self.rate
  end

  def outside_bounds?(conversion_rate)
    conversion_rate.rate > self.rate && conversion_rate.minimum_offerwall_bid < self.minimum_offerwall_bid
  end

  def inside_bounds?(conversion_rate)
    conversion_rate.rate < self.rate && conversion_rate.minimum_offerwall_bid > self.minimum_offerwall_bid
  end
end
