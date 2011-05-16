class AddShowGalleryToCurrency < ActiveRecord::Migration
  def self.up
    add_column :currencies, :show_gallery, :boolean, :default => false
  end

  def self.down
    remove_column :currencies, :show_gallery
  end
end
