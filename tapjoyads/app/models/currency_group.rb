class CurrencyGroup < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :currencies

  validates_presence_of :name

  after_save :cache_currencies

  PRECACHE_WEIGHT_COLUMNS = [ :normal_conversion_rate, :normal_bid, :normal_price, :normal_avg_revenue, :random, :over_threshold, :rank_boost ]
  POSTCACHE_WEIGHT_COLUMNS = [ :category_match ]
  WEIGHTS = PRECACHE_WEIGHT_COLUMNS + POSTCACHE_WEIGHT_COLUMNS

  def precache_weights
    PRECACHE_WEIGHT_COLUMNS.inject({}) { |weights_hash, column| weights_hash[column] = send(column); weights_hash }
  end

  def postcache_weights
    POSTCACHE_WEIGHT_COLUMNS.inject({}) { |weights_hash, column| weights_hash[column] = send(column); weights_hash }
  end

  private

  def cache_currencies
    currencies.each(&:cache) if POSTCACHE_WEIGHT_COLUMNS.inject(false) { |weights_changed, column| send("#{column}_changed?") || weights_changed }
  end

end
