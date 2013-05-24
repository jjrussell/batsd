class CreateVideoButtons < ActiveRecord::Migration
  def self.up
    create_table :video_buttons, :id => false do |t|
      t.guid    :id, :null => false
      t.guid    :video_offer_id, :null => false
      t.string  :name, :null => false
      t.string  :url, :null => false
      t.integer :ordinal
      t.boolean :enabled, :default => true
      t.timestamps
    end

    add_index :video_buttons, :id, :unique => true
    add_index :video_buttons, :video_offer_id
  end

  def self.down
    drop_table :video_buttons
  end
end
