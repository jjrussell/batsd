class AddImageSourceToGamers < ActiveRecord::Migration
  def self.up
    add_column :gamers, :image_source, :integer, :default => Gamer::IMAGE_SOURCE_GRAVATAR
  end

  def self.down
    remove_column :gamers, :image_source
  end
end
