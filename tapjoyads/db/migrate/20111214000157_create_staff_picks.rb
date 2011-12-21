class CreateStaffPicks < ActiveRecord::Migration
  def self.up
    create_table :staff_picks, :id => false do |t|
      t.guid    :id, :null => false
      t.guid    :offer_id
      t.guid    :author_id
      t.string  :offer_type, :null => false
      t.text    :platforms, :null => false
      t.string  :subtitle, :null => false
      t.string  :offer_title, :null => false
      t.text    :description, :null => false
      t.string  :main_icon_url
      t.string  :secondary_icon_url
      t.string  :button_text, :null => true, :default => nil
      t.string  :button_url, :null => true, :default => nil
      t.date    :start_date, :null => false
      t.date    :end_date, :null => false
      t.integer :weight, :null => false, :default => 0

      t.timestamps
    end

    add_index :staff_picks, :id, :unique => true
    add_index :staff_picks, :offer_type, :unique => false
  end

  def self.down
    drop_table :staff_picks
  end
end
