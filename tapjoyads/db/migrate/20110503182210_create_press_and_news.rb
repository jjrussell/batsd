class CreatePressAndNews < ActiveRecord::Migration
  def self.up
    create_table :press_releases do |t|
      t.timestamp   :published_at,    :nil => false
      t.text        :link_text,       :nil => false
      t.text        :link_href,       :nil => false
      # internal only
      t.string      :link_id
      t.text        :content_title
      t.text        :content_subtitle
      t.text        :content_body
      t.text        :content_about
      t.text        :content_contact

      t.timestamps
    end

    create_table :news_coverages do |t|
      t.timestamp   :published_at,  :nil => false
      t.string      :link_source,   :nil => false
      t.text        :link_text,     :nil => false
      t.text        :link_href,     :nil => false

      t.timestamps
    end

    add_index :press_releases, :published_at
    add_index :news_coverages, :published_at
  end

  def self.down
    drop_table :press_releases
    drop_table :news_coverages
  end
end
