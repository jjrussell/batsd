class Wfh < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :employee

  CATEGORIES = %w( WFH PTO Conference )
  validates_inclusion_of :category, :in => CATEGORIES

  named_scope :today_and_after, lambda {
    { :conditions => [ 'end_date >= ?', Date.today ] }
  }
  named_scope :today, lambda {
    today = Date.today
    { :conditions => [ 'start_date <= ? AND end_date >= ?', today, today ] }
  }
  named_scope :upcoming_week, lambda {
    start_date = Date.today + 1.day
    end_date   = start_date + 7.days
    {
      :joins => [ :employee ],
      :conditions => [ 'start_date >= ? AND start_date <= ?', start_date, end_date ],
      :order => [ 'start_date, end_date, employees.first_name, employees.last_name' ]
    }
  }


  def pto?; category == 'PTO'; end
  def conference?; category == 'Conference'; end

  def <=>(other)
    [ employee_id, start_date, end_date ] <=>
    [ other.employee_id, other.start_date, other.end_date ]
  end
end
