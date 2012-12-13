module CacheCurrency
  extend ActiveSupport::Concern

  included do
    after_save :cache_currency
  end

  def cache_currency
    currency.cache
  end
end
