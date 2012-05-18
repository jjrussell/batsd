class Wfh < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :employee

  CATEGORIES = [
    [ 'Working From Home', 'wfh'   ],
    [ 'Paid Time Off',     'pto'   ],
    [ 'Out Of Office',     'ooo'   ],
    [ 'Arriving late',     'late'  ],
    [ 'Leaving early',     'early' ],
  ]
  validates_inclusion_of :category, :in => CATEGORIES.map(&:last)

  scope :today_and_after, lambda {
    { :conditions => [ 'end_date >= ?', Time.zone.today ] }
  }
  scope :today, lambda {
    today = Time.zone.today
    { :conditions => [ 'start_date <= ? AND end_date >= ?', today, today ] }
  }
  scope :upcoming_week, lambda {
    start_date = Time.zone.today + 1.day
    end_date   = start_date + 7.days
    {
      :joins => [ :employee ],
      :conditions => [ 'start_date >= ? AND start_date <= ?', start_date, end_date ],
      :order => [ 'start_date, end_date, employees.first_name, employees.last_name' ]
    }
  }

  def multi_day?
    start_date != end_date
  end

  def <=>(other)
    [ employee_id, start_date, end_date ] <=>
    [ other.employee_id, other.start_date, other.end_date ]
  end
end
