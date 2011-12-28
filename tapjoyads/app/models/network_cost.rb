class NetworkCost < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :first_effective_on
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false

  named_scope :for_date, lambda { |date| { :conditions => [ "first_effective_on = ? OR (first_effective_on > ? AND first_effective_on < ?)", date, date - 30.days, date ] } }
end
