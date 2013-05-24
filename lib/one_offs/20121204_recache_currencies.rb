class OneOffs
  def self.recache_currencies
    Currency.cache_all
  end
end
