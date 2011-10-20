class AppReview < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app

  before_save :copy_platform

  validates_uniqueness_of [:featured_on, :platform], :allow_nil => true
  validates_uniqueness_of :author_id, :scope => :app_id, :message => "has already reviewed this app"
  validates_presence_of :author, :app, :text

  named_scope :by_employees, :conditions => { :author_type => 'Employee' }
  named_scope :ordered_by_date, :order => "featured_on DESC"
  named_scope :not_featured, :conditions => { :featured_on => nil }, :limit => 1, :order => "created_at DESC"
  named_scope :featured_before,  lambda { |date| { :conditions => [ "featured_on < ?", date.to_date ], :order => "featured_on ASC", :limit => 1 } }
  named_scope :featured_on, lambda { |date| { :conditions => [ "featured_on = ?", date.to_date ] } }
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platform = ?", platform ] } }

  delegate :name, :id, :to => :app, :prefix => true
  delegate :full_name, :to => :author, :prefix => true

  def self.featured_review(platform)
    platform = 'iphone' unless %w(android iphone).include?(platform)
    Mc.get_and_put("featured_app_review.#{platform}", false, 1.hour) do
      now = Time.now.utc
      review =  AppReview.featured_on(now).for_platform(platform).first ||
                AppReview.by_employees.not_featured.for_platform(platform) ||
                AppReview.featured_before(now).for_platform(platform)

      if review.nil?
        Notifier.alert_new_relic(AppReviewEmptyError, "Platform #{platform}, Time #{now}")
        raise
      else
        review.featured_on = now
        review.save
        review
      end
    end
  end

private

  def copy_platform
    self.platform = app.platform
  end
end
