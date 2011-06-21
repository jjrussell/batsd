class NewsCoverage < ActiveRecord::Base
  include UuidPrimaryKey

  named_scope :ordered, :order => "published_at DESC"
end
