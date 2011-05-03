class NewsCoverage < ActiveRecord::Base
  named_scope :recent, lambda { |num| { :order => "published_at DESC", :limit => num } }
end
