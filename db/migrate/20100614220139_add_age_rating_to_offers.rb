class AddAgeRatingToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :age_rating, :integer
  end

  def self.down
    remove_column :offers, :age_rating
  end
end
