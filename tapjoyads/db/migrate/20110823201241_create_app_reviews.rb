class CreateAppReviews < ActiveRecord::Migration
  def self.up
    create_table :app_reviews, :id => false do |t|
      t.guid    :id,            :null => false
      t.guid    :app_id,        :null => false
      t.guid    :author_id,     :null => false
      t.string  :author_type,   :null => false
      t.string  :text,          :null => false
      t.date    :featured_on

      t.timestamps
    end

    add_index :app_reviews, :id, :unique => true
    add_index :app_reviews, [ :app_id, :author_id ], :unique => true
  end

  def self.down
    drop_table :app_reviews
  end
end
