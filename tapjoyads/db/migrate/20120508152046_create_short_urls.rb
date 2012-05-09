class CreateShortUrls < ActiveRecord::Migration
  def self.up
    create_table :short_urls, :id => false do |t|
      t.guid   :id,          :null => false
      t.string :token,       :null => false
      t.text   :long_url,    :null => false
      t.date   :expiry

      t.timestamps
    end

    add_index :short_urls, :id, :unique => true
    add_index :short_urls, :token, :unique => true
  end

  def self.down
    drop_table :short_urls
  end
end
