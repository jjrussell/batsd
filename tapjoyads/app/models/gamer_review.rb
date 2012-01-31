class GamerReview < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app

  before_save :copy_platform
  before_destroy :reset_app_rating_counts

  validates_uniqueness_of :author_id, :scope => :app_id, :if => :app, :message => "has already reviewed this app"
  validates_presence_of :author, :app, :text

  named_scope :by_gamers, :conditions => { :author_type => 'Gamer' }
  named_scope :ordered_by_date, :order => "created_at DESC"
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platform = ?", platform ] } }

  delegate :name, :id, :to => :app, :prefix => true
  delegate :get_gamer_name, :to => :author, :prefix => true

  def update_app_rating_counts(prev_rating)
    return true if self.user_rating == prev_rating

    if self.user_rating > 0
      self.app.thumb_up_count += 1
      self.app.thumb_down_count -= 1 if prev_rating < 0
    end

    if self.user_rating < 0
      self.app.thumb_down_count += 1
      self.app.thumb_up_count -= 1 if prev_rating > 0
    end

    self.app.save
  end

  private

  def copy_platform
    self.platform = app.platform
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
