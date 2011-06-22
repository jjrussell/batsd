class Job < ActiveRecord::Base
  include UuidPrimaryKey
  
  JOB_TYPES = %w( master queue )
  FREQUENCIES = %w( interval hourly daily )
  
  validates_presence_of :controller, :action
  validates_inclusion_of :job_type, :in => JOB_TYPES
  validates_inclusion_of :frequency, :in => FREQUENCIES
  validates_inclusion_of :active, :in => [ true, false ]
  validates_numericality_of :seconds, :only_integer => true, :greater_than => 0
  validates_each :seconds do |record, attribute, value|
    if record.frequency == 'daily'
      record.errors.add(attribute, 'should be less than 1 day') unless value < 1.day.to_i
    else
      record.errors.add(attribute, 'should be less than 1 hour') unless value < 1.hour.to_i
    end
  end
  
  named_scope :active, :conditions => 'active = true'
  named_scope :by_job_type, lambda { |type| { :conditions => [ "job_type = ?", type ] } }
  
  attr_reader :next_run_time
  
  def set_next_run_time
    now = Time.now.utc
    if frequency == 'interval'
      @next_run_time = now + seconds
    elsif frequency == 'hourly'
      if @next_run_time.present?
        @next_run_time += 1.hour
      else
        @next_run_time = now.beginning_of_day + now.hour.hours + seconds
        @next_run_time += 1.hour if now > @next_run_time
      end
    elsif frequency == 'daily'
      if @next_run_time.present?
        @next_run_time += 1.day
      else
        @next_run_time = now.beginning_of_day + seconds
        @next_run_time += 1.day if now > @next_run_time
      end
    end
  end
  
  def frequency_in_words
    time = Time.at(seconds).utc
    case frequency
    when 'interval'
      "every #{time.to_s(:mm_ss)}"
    when 'hourly'
      "each hour at #{time.to_s(:mm_ss)}"
    when 'daily'
      "each day at #{time.to_s(:hh_mm_ss)}"
    end
  end
  
  def job_path
    "#{controller}/#{action}"
  end
  
end
