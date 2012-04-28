class ReviewModerationVote < ActiveRecord::Base
  include UuidPrimaryKey
  validates_uniqueness_of :gamer_id, :scope => [:app_review_id, :type], :message => "has already flagged this app"
end

class HelpfulVote < ReviewModerationVote
  belongs_to :app_review, :counter_cache => :helpful_votes_count
  belongs_to :gamer

  after_create :incr_sum_on_app_review
  after_create :incr_count_on_gamer

  before_destroy :decr_sum_on_app_review
  before_destroy :decr_count_on_gamer

  def incr_count_on_gamer
    if app_review.author && app_review.author.class == 'Gamer'
      app_review.author.been_helpful_count ||= 0
      app_review.author.been_helpful_count += 1
      app_review.author.save
    end
  end

  def decr_count_on_gamer
    if app_review.author && app_review.author.class == 'Gamer'
      app_review.author.been_helpful_count ||= 0
      app_review.author.been_helpful_count -= 1
      app_review.author.been_helpful_count = 0 if gamer.been_helpful_count < 0
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

  after_create :incr_count_on_gamer
  before_destroy :decr_count_on_gamer

  def incr_count_on_gamer
    if app_review.author && app_review.author.class == 'Gamer'
      app_review.author.been_buried_count ||= 0
      app_review.author.been_buried_count += 1
      app_review.author.save
    end
  end

  def decr_count_on_gamer
    if app_review.author && app_review.author.class == 'Gamer'
      app_review.author.been_buried_count ||= 0
      app_review.author.been_buried_count -= 1
      app_review.author.been_buried_count = 0 if gamer.been_buried_count < 0
      app_review.author.save
    end
  end
end
