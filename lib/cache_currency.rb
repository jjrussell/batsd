#this module is being used for currency sales and
#conversion rates to re-cache the currency on a
#save or destroy to get a fresh snapshot of the
#memoized methods under currency:
#active_and_future_sales and all_conversion_rates
module CacheCurrency
  extend ActiveSupport::Concern

  included do
    after_save :send_currency_to_cache
    after_destroy :send_currency_to_cache
  end

  def send_currency_to_cache
    currency.cache
  end
end
