class CreateFeaturedContents < ActiveRecord::Migration
  def self.up
    create_table :featured_contents, :id => false do |t|
      t.guid    :id, :null => false
      t.guid    :offer_id
      t.guid    :author_id
      t.string  :featured_type, :null => false
      t.text    :platforms, :null => false
      t.text    :subtitle, :null => false
      t.text    :title, :null => false
      t.text    :description, :null => false
      t.text    :main_icon_url
      t.text    :secondary_icon_url
      t.text    :button_text, :null => true, :default => nil
      t.text    :button_url, :null => true, :default => nil
      t.date    :start_date, :null => false
      t.date    :end_date, :null => false
      t.integer :weight, :null => false, :default => 0

      t.timestamps
    end

    add_index :featured_contents, :id, :unique => true
    add_index :featured_contents, :featured_type, :unique => false
  end

  def self.down
    drop_table :featured_contents
  end
end
