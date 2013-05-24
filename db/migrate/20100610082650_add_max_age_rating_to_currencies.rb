class AddMaxAgeRatingToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :max_age_rating, :integer
  end

  def self.down
    remove_column :currencies, :max_age_rating
  end
end
