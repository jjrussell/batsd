# == Schema Information
#
# Table name: jobs
#
#  id              :string(36)      not null, primary key
#  active          :boolean(1)      default(FALSE), not null
#  job_type        :string(255)     not null
#  controller      :string(255)     not null
#  action          :string(255)     default("index"), not null
#  frequency       :string(255)     not null
#  seconds         :integer(4)      not null
#  created_at      :datetime
#  updated_at      :datetime
#  max_concurrency :integer(4)      default(0), not null
#

class Job < ActiveRecord::Base
  include UuidPrimaryKey

  JOB_TYPES = %w( master queue internal )
  FREQUENCIES = %w( interval hourly daily )
  CONCURRENCY_DIR = "#{Rails.root}/tmp/job_concurrency"

  validates_presence_of :controller, :action
  validates_inclusion_of :job_type, :in => JOB_TYPES
  validates_inclusion_of :frequency, :in => FREQUENCIES
  validates_inclusion_of :active, :in => [ true, false ]
  validates_numericality_of :seconds, :max_concurrency, :only_integer => true, :greater_than_or_equal_to => 0
  validates_each :seconds, :allow_nil => true do |record, attribute, value|
    if record.frequency == 'daily'
      record.errors.add(attribute, 'should be less than 1 day') unless value < 1.day.to_i
    else
      record.errors.add(attribute, 'should be less than 1 hour') unless value < 1.hour.to_i
    end
  end
  validate :check_job_path

  scope :active, :conditions => 'active = true'
  scope :by_job_type, lambda { |type| { :conditions => [ "job_type = ?", type ] } }
  scope :for_index, :order => "active desc, job_type, frequency, seconds"

  attr_reader :next_run_time

  def path
    "/job/#{self.controller}/#{self.action}"
  end

  def url
    return nil unless job_type == 'master' # shouldn't be a need for url unless job_type is master
    "#{MASTERJOBS_URL}#{path}"
  end

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
    time = (Time.now.utc.beginning_of_day + seconds).in_time_zone(Time.zone)
    case frequency
    when 'interval'
      return 'every second'         if seconds == 0
      str = 'every'
      str += " #{time.min} minutes" if time.min > 0
      str += " #{time.sec} seconds" if time.sec > 0
      str
    when 'hourly'
      return 'hourly on the hour'   if seconds == 0
      str = 'hourly at'
      str += " #{time.min} minutes" if time.min > 0
      str += " #{time.sec} seconds" if time.sec > 0
      str += ' past the hour'
    when 'daily'
      "daily at #{time.to_s(:ampm)}"
    end
  end

  def job_path
    "#{controller}/#{action}"
  end

  def concurrency_filename(unicorn_pid, guid = nil)
    "#{unicorn_pid}.#{controller}_#{action[0...((action =~ /\?/) || action.size)]}.#{guid}"
  end

  private

  def check_job_path
    if controller_changed? || action_changed?
      begin
        c = "Job::#{controller.camelize}Controller".constantize
        errors.add(:action, 'does not exist.') unless c.action_methods.include?(action.split('?').first)
      rescue NameError => e
        errors.add(:controller, 'does not exist.')
      end
    end
  end

end
