class NewsCoverage < ActiveRecord::Base
  include UuidPrimaryKey

  scope :ordered, :order => "published_at DESC"
  scope :not_future, :conditions => ["published_at < ?", Time.zone.now.end_of_day]
end
