class CreateReviewModerationVotes < ActiveRecord::Migration
  def self.up
    create_table :review_moderation_votes, :id => false do |t|
      t.guid    :id, :null => false
      t.string  :app_review_id, :limit => 36, :null => false
      t.string  :gamer_id, :limit => 36, :null => false
      t.string  :type, :limit => 32
      t.integer :value
      t.timestamps
    end
    add_index :review_moderation_votes, :id, :unique => true
    add_index :review_moderation_votes, [:type, :app_review_id]
    add_index :review_moderation_votes, [:type, :gamer_id]

  end

  def self.down
    drop_table :review_moderation_votes
  end
end
