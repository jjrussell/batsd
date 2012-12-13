class CurrencySale < ActiveRecord::Base
  include UuidPrimaryKey
  include CacheCurrency #This starts a currency sale immediately by caching the currency

  MULTIPLIER_SELECT = [1.5, 2.0, 3.0]
  START_TIME_ALLOWANCE = 1.hour
  OVERLAP_ERROR    = "Cannot create currency sale. You have already created a currency sale for this time frame.
                      Either edit the currency sale for the times you entered, or use different times."
  TIME_TRAVEL_FAIL = "Cannot create currency sale. You are trying to create a currency sale in a
                      time frame that has already passed us by."
  HELP_MESSAGE     = "Currency Sales allow you to run time-based sales to increase the amount of virtual
                      currency a user earns, and help spread the word of your sale fast with custom messages."

  belongs_to :currency

  validates :start_time,       :presence => true
  validates :end_time,         :presence => true
  validates :multiplier,       :inclusion => { :in => CurrencySale::MULTIPLIER_SELECT,
                                               :message => "must be a multiplier value from the dropdown" }
  validates :message_enabled,  :inclusion => { :in => [ true, false ] }

  validate :validate_start_end, :validate_in_the_future, :validate_not_overlapping_times, :if => :time_changed?

  scope :active,   lambda { where("start_time <= ? AND end_time > ?", Time.zone.now, Time.zone.now) }
  scope :past,     lambda { where("start_time < ? AND end_time < ?", Time.zone.now, Time.zone.now).order('start_time') }
  scope :future,   lambda { where("start_time > ? AND end_time > ?", Time.zone.now, Time.zone.now).order('start_time') }

  #
  # Predicate queries
  #
  def past?
    now = Time.zone.now
    start_time < now && end_time < now
  end

  def starts_recently_or_in_future?
    start_time > START_TIME_ALLOWANCE.ago
  end

  def ends_in_future?
    Time.current < end_time
  end

  def time_changed?
    self.start_time.present? && self.end_time.present? && [self.start_time_changed?, self.end_time_changed?].any?
  end

  def multiplier_to_string
    (self.multiplier % 1) == 0 ? self.multiplier.to_i.to_s : self.multiplier.to_s
  end

  def currency_sale_message(pub, currency_name)
    "#{pub} is having a currency sale! Earn #{self.multiplier_to_string}x #{currency_name}!"
  end

protected

  # The time range is responsible for comparisons between itself and other ranges
  def time_range
    start_time..end_time
  end

private

  #
  # Validation methods
  # Responsible for checking constraints and adding errors to the instance
  #
  def validate_in_the_future
    validate_starts_recently_or_in_future and return if start_time_changed?
    validate_ends_in_future if end_time_changed?
  end

  def validate_starts_recently_or_in_future
    add_time_travel_error unless starts_recently_or_in_future?
  end

  def validate_ends_in_future
    add_time_travel_error unless ends_in_future?
  end

  def validate_start_end
    errors.add :end_time, "must be after Start Time" if self.start_time >= self.end_time
  end

  def validate_not_overlapping_times
    # Search for a sale with an overlapping time range
    currency.currency_sales.detect do |currency_sale|
      next if currency_sale == self

      errors.add(:base, OVERLAP_ERROR) if overlapping?(currency_sale)
    end
  end


  #
  #

  # Failure helper
  def add_time_travel_error
    errors.add :base, TIME_TRAVEL_FAIL
  end

  def overlapping?(currency_sale)
    time_range.overlaps?(currency_sale.time_range)
  end
end
