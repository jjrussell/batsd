class CreateGamerReviews < ActiveRecord::Migration
  def self.up
    create_table :gamer_reviews, :id => false do |t|
      t.guid    :id,            :null => false
      t.guid    :app_id,        :null => false
      t.guid    :author_id,     :null => false
      t.string  :author_type,   :null => false
      t.string  :platform,      :null => false
      t.text    :text,          :null => false
      t.float   :user_rating

      t.timestamps
    end

    add_index :gamer_reviews, :id, :unique => true
    add_index :gamer_reviews, [ :app_id, :author_id ], :unique => true
  end

  def self.down
    drop_table :gamer_reviews
  end
end
