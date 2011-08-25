class AppReview < ActiveRecord::Base
  include UuidPrimaryKey

  attr_accessible :app_id, :text, :featured_on

  belongs_to :author, :polymorphic => true
  belongs_to :app

  validates_uniqueness_of :featured_on
  validates_presence_of :author, :app, :text

  named_scope :by_employees, :conditions => { :author_type => 'Employee' }
  named_scope :not_featured, :conditions => { :featured_on => nil }, :limit => 1, :order => "created_at DESC"
  named_scope :featured_before,  lambda { |date| { :conditions => [ "featured_on < ?", date.to_date ], :order => "featured_on ASC", :limit => 1 } }
  named_scope :featured_on, lambda { |date| { :conditions => [ "featured_on = ?", date.to_date ] } }

  delegate :name, :id, :to => :app, :prefix => true
  delegate :full_name, :to => :author, :prefix => true

  def self.featured_review
    Mc.get_and_put("featured_app_review", false, 1.hour) do
      review = AppReview.featured_on(Time.zone.now).first ||
              AppReview.by_employees.not_featured.first ||
              AppReview.featured_before(Time.zone.now).first

      review.featured_on = Time.zone.now
      review.save
      review
    end
  end
end
