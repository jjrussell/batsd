class ReviewModerationVote < ActiveRecord::Base
  include UuidPrimaryKey
  validates_uniqueness_of :gamer_id, :scope => [:app_review_id, :type], :message => "has already flagged this app"
end

class HelpfulVote < ReviewModerationVote
  belongs_to :app_review, :counter_cache => :helpful_votes_count
  belongs_to :gamer, :counter_cache => :helpful_votes_count

  def after_create
    app_review.helpful_values_sum = app_review.helpful_values_sum + self.value
    app_review.save
  end

  def after_destroy
    app_review.helpful_values_sum = app_review.helpful_values_sum - self.value
    app_review.save
  end
end

class BuryVote < ReviewModerationVote
  belongs_to :app_review, :counter_cache => :bury_votes_count
  belongs_to :gamer, :counter_cache => :bury_votes_count
end
