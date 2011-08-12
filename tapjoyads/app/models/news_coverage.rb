class NewsCoverage < ActiveRecord::Base
  include UuidPrimaryKey

  named_scope :ordered, :order => "published_at DESC"
  named_scope :not_future, :conditions => ["published_at < ?", Time.zone.now.end_of_day]
end
