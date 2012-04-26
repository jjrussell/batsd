class ReviewModerationVote < ActiveRecord::Base
  include UuidPrimaryKey
  validates_uniqueness_of :gamer_id, :scope => [:app_review_id, :type], :message => "has already flagged this app"
end

class HelpfulVote < ReviewModerationVote
  belongs_to :app_review, :counter_cache => :helpful_votes_count
  belongs_to :gamer  #, :counter_cache => :helpful_votes_count

  after_create :incr_sum_on_app_review
  after_create :incr_count_on_gamer

  before_destroy :decr_sum_on_app_review
  before_destroy :decr_count_on_gamer

  def incr_count_on_gamer
    gamer.extra_attributes[:helpful_votes_count] ||= 0
    gamer.extra_attributes[:helpful_votes_count] += 1
    gamer.save

  end

  def decr_count_on_gamer
    gamer.extra_attributes[:helpful_votes_count] ||= 0
    gamer.extra_attributes[:helpful_votes_count] -= 1
    gamer.extra_attributes[:helpful_votes_count] = 0 if gamer.extra_attributes[:helpful_votes_count] < 0
    gamer.save

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
  belongs_to :gamer #, :counter_cache => :bury_votes_count

  after_create :incr_count_on_gamer
  before_destroy :decr_count_on_gamer

  def incr_count_on_gamer
    gamer.extra_attributes[:bury_votes_count] ||= 0
    gamer.extra_attributes[:bury_votes_count] += 1
    gamer.save
  end

  def decr_count_on_gamer
    gamer.extra_attributes[:bury_votes_count] ||= 0
    gamer.extra_attributes[:bury_votes_count] -= 1
    gamer.extra_attributes[:bury_votes_count] = 0 if gamer.extra_attributes[:bury_votes_count] < 0
    gamer.save
  end

end
