class AddReviewModerationVotesCountToGamers < ActiveRecord::Migration
  def self.up
    # TODO: create a table for banned_reviewers
    #add_column :gamers, :helpful_votes_count, :integer , :default => 0
    #add_column :gamers, :bury_votes_count, :integer , :default => 0
  end

  def self.down
    #remove_column :gamers, :bury_votes_count
    #remove_column :gamers, :helpful_votes_count
  end
end
