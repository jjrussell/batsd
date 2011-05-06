class NewsCoverage < ActiveRecord::Base
  named_scope :ordered, :order => "published_at DESC"
end
