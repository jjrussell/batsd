class AddCategoryToGenericOffer < ActiveRecord::Migration
  def self.up
    add_column :generic_offers, :category, :string
  end

  def self.down
    remove_column :generic_offers, :category
  end
end
