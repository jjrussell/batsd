class RemoveShowGalleryFromCurrencies < ActiveRecord::Migration
  def self.up
    remove_column :currencies, :show_gallery
  end

  def self.down
    add_column :currencies, :show_gallery, :boolean, :default => false
  end
end
