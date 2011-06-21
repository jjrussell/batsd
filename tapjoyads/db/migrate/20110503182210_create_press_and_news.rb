class CreatePressAndNews < ActiveRecord::Migration
  def self.up
    create_table :press_releases, :id => false do |t|
      t.column      :id, 'char(36) binary', :null => false
      t.timestamp   :published_at,    :null => false
      t.text        :link_text,       :null => false
      t.text        :link_href,       :null => false
      # internal only
      t.string      :link_id
      t.text        :content_title
      t.text        :content_subtitle
      t.text        :content_body
      t.text        :content_about
      t.text        :content_contact

      t.timestamps
    end

    create_table :news_coverages, :id => false do |t|
      t.column      :id, 'char(36) binary', :null => false
      t.timestamp   :published_at,  :null => false
      t.string      :link_source,   :null => false
      t.text        :link_text,     :null => false
      t.text        :link_href,     :null => false

      t.timestamps
    end

    add_index :press_releases, :id, :unique => true
    add_index :news_coverages, :id, :unique => true
    add_index :press_releases, :published_at
    add_index :news_coverages, :published_at
  end

  def self.down
    drop_table :press_releases
    drop_table :news_coverages
  end
end
