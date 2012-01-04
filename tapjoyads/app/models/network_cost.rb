class NetworkCost < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :first_effective_on
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false

  named_scope :for_date, lambda { |date| { :conditions => [ "first_effective_on > ? AND first_effective_on <= ?", date - 30.days, date ] } }

  def last_effective_on
    first_effective_on + 29.days
  end

end
