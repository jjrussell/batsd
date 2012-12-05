class CurrencySale < ActiveRecord::Base
  include UuidPrimaryKey

  MULTIPLIER_SELECT = [1.5, 2.0, 3.0]
  START_TIME_ALLOWANCE = 1.hour

  belongs_to :currency

  validates_presence_of :start_time, :end_time, :multiplier
  validates_uniqueness_of :start_time, :end_time
  validates_numericality_of :multiplier, :greater_than => 0
  validate :validate_start_end, :validate_in_the_future, :validate_not_overlapping_times, :if => :time_changed?
  validates_each :multiplier do |record, attribute, value|
    record.errors.add(attribute, I18n.t('text.currency_sale.must_be_dropdown')) unless CurrencySale::MULTIPLIER_SELECT.include?(value)
  end
  validates_inclusion_of :message_enabled, :in => [ true, false ]

  scope :active, lambda { { :conditions => [ "start_time <= ? AND end_time > ?", Time.zone.now, Time.zone.now ] } }
  scope :past, lambda { { :conditions => [ "start_time < ? AND end_time < ?", Time.zone.now, Time.zone.now ], :order => 'start_time' } }
  scope :future, lambda { { :conditions => [ "start_time > ? AND end_time > ?", Time.zone.now, Time.zone.now ], :order => 'start_time' } }

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

  def validate_overlapping_errors(currency_sale)
    errors.add(:base, I18n.t('text.currency_sale.overlap_error')) if overlapping?(currency_sale)
  end

  def validate_in_the_future
    if start_time_changed?
      add_time_travel_error unless starts_recently_or_in_future?
    elsif end_time_changed?
      add_time_travel_error unless ends_in_future?
    end
  end

  def validate_start_end
    errors.add :end_time, "must be after Start Time" if self.start_time >= self.end_time
  end

  def validate_not_overlapping_times
    # Search for a sale with an overlapping time range
    currency.currency_sales.detect do |currency_sale|
      next if currency_sale == self

      validate_overlapping_errors(currency_sale)
    end
  end


  #
  #

  # Failure helper
  def add_time_travel_error
    errors.add :base, I18n.t('text.currency_sale.time_travel_fail')
  end

  def overlapping?(currency_sale)
    time_range.overlaps?(currency_sale.time_range)
  end
end
