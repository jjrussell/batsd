class AddItemToVideoButtons < ActiveRecord::Migration
  def self.up
    add_guid_column :video_buttons, :item_id
    add_column :video_buttons, :item_type, :string
  end

  def self.down
    remove_column :video_buttons, :item_id, :item_type
  end
end
