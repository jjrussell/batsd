class CurrencySale < ActiveRecord::Base
  include UuidPrimaryKey
  include CacheCurrency #This starts a currency sale immediately by caching the currency

  MULTIPLIER_SELECT = [1.5, 2.0, 3.0]
  START_TIME_ALLOWANCE = 1.hour

  belongs_to :currency

  validates :start_time,       :presence => true
  validates :end_time,         :presence => true
  validates :multiplier,       :inclusion => { :in => CurrencySale::MULTIPLIER_SELECT,
                                               :message => I18n.t('text.currency_sale.must_be_dropdown') }
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
    errors.add :end_time, I18n.t('text.currency_sale.start_before_end_error') if self.start_time >= self.end_time
  end

  def validate_not_overlapping_times
    # Search for a sale with an overlapping time range
    currency.currency_sales.detect do |currency_sale|
      next if currency_sale == self

      errors.add(:base, I18n.t('text.currency_sale.overlap_error')) if overlapping?(currency_sale)
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
