class GamerReview < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app

  before_save :copy_platform
  after_save :update_app_rating_counts
  before_destroy :reset_app_rating_counts

  validates_uniqueness_of :author_id, :scope => :app_id, :if => :app, :message => "has already reviewed this app"
  validates_presence_of :author, :app, :text

  named_scope :by_gamers, :conditions => { :author_type => 'Gamer' }
  named_scope :ordered_by_date, :order => "created_at DESC"

  delegate :name, :id, :to => :app, :prefix => true
  delegate :get_gamer_name, :to => :author

  attr_accessor :prev_rating
  cattr_reader :per_page
  @@per_page = 10

  private

  def copy_platform
    self.platform = app.platform
  end

  def update_app_rating_counts
    return true if self.user_rating == prev_rating

    if self.user_rating > 0
      app.thumb_up_count += 1
      app.thumb_down_count -= 1 if prev_rating < 0
    end

    if self.user_rating < 0
      app.thumb_down_count += 1
      app.thumb_up_count -= 1 if prev_rating > 0
    end

    app.save
  end

  def reset_app_rating_counts
    if self.user_rating > 0
      app.thumb_up_count -= 1
    elsif self.user_rating < 0
      app.thumb_down_count -= 1
    end

    app.save
  end
end
