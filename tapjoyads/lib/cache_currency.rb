module CacheCurrency
  extend ActiveSupport::Concern

  included do
    after_save :send_currency_to_cache
  end

  def send_currency_to_cache
    currency.cache
  end
end
