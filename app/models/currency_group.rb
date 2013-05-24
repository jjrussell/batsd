# == Schema Information
#
# Table name: currency_groups
#
#  id                     :string(36)      not null, primary key
#  normal_conversion_rate :integer(4)      default(0), not null
#  normal_bid             :integer(4)      default(0), not null
#  normal_price           :integer(4)      default(0), not null
#  normal_avg_revenue     :integer(4)      default(0), not null
#  random                 :integer(4)      default(0), not null
#  over_threshold         :integer(4)      default(0), not null
#  name                   :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  rank_boost             :integer(4)      default(0), not null
#  category_match         :integer(4)      default(0), not null
#

class CurrencyGroup < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :currencies

  validates_presence_of :name

  after_save :cache_currencies

  PRECACHE_WEIGHT_COLUMNS = [ :normal_conversion_rate, :normal_bid, :normal_price, :normal_avg_revenue, :random, :over_threshold, :rank_boost ]
  POSTCACHE_WEIGHT_COLUMNS = [ :category_match ]
  WEIGHTS = PRECACHE_WEIGHT_COLUMNS + POSTCACHE_WEIGHT_COLUMNS
  DEFAULT_ID = "0c3d2212-ce65-47eb-835e-ac6f5f915c24"

  DEFAULT_WEIGHTS = {
    :normal_conversion_rate => 3,
    :normal_bid => 1,
    :normal_price => -2,
    :normal_avg_revenue => 5,
    :over_threshold => 6,
    :rank_boost => 1
  }

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
