class AddCategoryMatchToCurrencyGroups < ActiveRecord::Migration
  def self.up
    add_column :currency_groups, :category_match, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :currency_groups, :category_match
  end
end
