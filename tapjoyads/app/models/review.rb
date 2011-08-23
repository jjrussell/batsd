class Review < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  belongs_to :author, :polymorphic => true
  belongs_to :app

  validates_uniqueness_of :featured_on
  validates_presence_of :author, :app, :text

  named_scope :not_featured_employee, :conditions => { :featured_on => nil, :author_type => 'Employee' }, :order => "created_at DESC"
  named_scope :already_featured, :conditions => [ "featured_on < ?", Time.zone.now.to_date ], :order => "featured_on ASC"
  named_scope :featured_on_date, lambda { |date| { :conditions => ["featured_on = ?", date.to_date] } }

  def self.featured_review
    review = Review.featured_on_date(Time.zone.now).first ||
             Review.not_featured_employee.first ||
             Review.already_featured.first

    review.featured_on = Time.zone.now
    review.save

    review
  end
end
