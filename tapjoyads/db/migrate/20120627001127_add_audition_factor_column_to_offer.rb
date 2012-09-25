class AddAuditionFactorColumnToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :audition_factor, :integer, :null => false, :default => Offer::Optimization::AUDITION_FACTORS[:medium]
  end

  def self.down
    remove_column :offers, :audition_factor
  end
end
