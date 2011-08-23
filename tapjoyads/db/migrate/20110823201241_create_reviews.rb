class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews, :id => false do |t|
      t.guid    :id,            :null => false
      t.guid    :app_id,        :null => false
      t.guid    :author_id,     :null => false
      t.string  :author_type,   :null => false
      t.string  :text,          :null => false
      t.date    :featured_on

      t.timestamps
    end

    add_index :reviews, :id, :unique => true
    add_index :reviews, :featured_on, :unique => true
    add_index :reviews, [ :app_id, :author_id ], :unique => true
  end

  def self.down
    drop_table :reviews
  end
end
