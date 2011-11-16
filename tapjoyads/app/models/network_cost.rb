class NetworkCost < ActiveRecord::Base
  include UuidPrimaryKey

  validates_numericality_of :amount, :only_integer => true, :allow_nil => false

  named_scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }
end
