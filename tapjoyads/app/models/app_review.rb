class AppReview < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app

  validates_uniqueness_of :featured_on, :allow_nil => true
  validates_uniqueness_of :author_id, :scope => :app_id, :message => "has already reviewed this app"
  validates_presence_of :author, :app, :text

  named_scope :by_employees, :conditions => { :author_type => 'Employee' }
  named_scope :ordered_by_date, :order => "featured_on DESC"
  named_scope :not_featured, :conditions => { :featured_on => nil }, :limit => 1, :order => "created_at DESC"
  named_scope :featured_before,  lambda { |date| { :conditions => [ "featured_on < ?", date.to_date ], :order => "featured_on ASC", :limit => 1 } }
  named_scope :featured_on, lambda { |date| { :conditions => [ "featured_on = ?", date.to_date ] } }

  delegate :name, :id, :to => :app, :prefix => true
  delegate :full_name, :to => :author, :prefix => true

  def self.featured_review(platform)
    Rails.logger.warn("\n\n[#{platform}]\n\n")
    platform = 'iphone' unless %w(android iphone).include?(platform)
    Mc.get_and_put("featured_app_review.#{platform}", false, 1.hour) do
      now = Time.now.utc
      reviews = AppReview.featured_on(now).select{|review| review.app.platform == platform}
      if reviews.blank?
        reviews = AppReview.by_employees.not_featured.select{|review| review.app.platform == platform}
        if reviews.blank?
          reviews = AppReview.featured_before(now).select{|review| review.app.platform == platform}
        end
      end

      Notifier.alert_new_relic(AppReviewEmptyError, "Platform #{platform}, Time #{now}") if reviews.blank?

      review = reviews.first
      review.featured_on = now
      review.save
      review
    end
  end
end
