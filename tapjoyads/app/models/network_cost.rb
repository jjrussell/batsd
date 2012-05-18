# == Schema Information
#
# Table name: network_costs
#
#  id                 :string(36)      not null, primary key
#  amount             :integer(4)      default(0), not null
#  notes              :text
#  created_at         :datetime
#  updated_at         :datetime
#  first_effective_on :date            not null
#

class NetworkCost < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :first_effective_on
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false

  scope :for_date, lambda { |date| { :conditions => [ "first_effective_on > ? AND first_effective_on <= ?", date - 30.days, date ] } }

  def last_effective_on
    first_effective_on + 29.days
  end

end
