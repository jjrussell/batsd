# == Schema Information
#
# Table name: review_moderation_votes
#
#  id            :string(36)      not null, primary key
#  app_review_id :string(36)      not null
#  gamer_id      :string(36)      not null
#  type          :string(32)
#  value         :integer(4)
#  created_at    :datetime
#  updated_at    :datetime
#

class ReviewModerationVote < ActiveRecord::Base
  include UuidPrimaryKey
  validates_uniqueness_of :gamer_id, :scope => [:app_review_id, :type], :message => "has already flagged this app"
end

class HelpfulVote < ReviewModerationVote
  belongs_to :app_review, :counter_cache => :helpful_votes_count
  belongs_to :gamer

  after_create :incr_sum_on_app_review
  after_create :incr_count_on_author

  before_destroy :decr_sum_on_app_review
  before_destroy :decr_count_on_author

  def incr_count_on_author
    if app_review.author && app_review.author.class == Gamer
      app_review.author.been_helpful_count ||= 0
      app_review.author.been_helpful_count += 1
      app_review.author.save
    end
  end

  def decr_count_on_author
    if app_review.author && app_review.author.class == Gamer
      app_review.author.been_helpful_count ||= 0
      app_review.author.been_helpful_count -= 1
      app_review.author.been_helpful_count = 0 if app_review.author.been_helpful_count < 0
      app_review.author.save
    end
  end

  def incr_sum_on_app_review
    app_review.helpful_values_sum = app_review.helpful_values_sum + self.value
    app_review.save
  end

  def decr_sum_on_app_review
    app_review.helpful_values_sum = app_review.helpful_values_sum - self.value
    app_review.save
  end
end

class BuryVote < ReviewModerationVote
  belongs_to :app_review, :counter_cache => :bury_votes_count
  belongs_to :gamer

  after_create :incr_count_on_author
  before_destroy :decr_count_on_author

  def incr_count_on_author
    if app_review.author && app_review.author.class == Gamer
      app_review.author.been_buried_count ||= 0
      app_review.author.been_buried_count += 1
      app_review.author.save
    end
  end

  def decr_count_on_author
    if app_review.author && app_review.author.class == Gamer
      app_review.author.been_buried_count ||= 0
      app_review.author.been_buried_count -= 1
      app_review.author.been_buried_count = 0 if app_review.author.been_buried_count < 0
      app_review.author.save
    end
  end
end
