class CurrencySale < ActiveRecord::Base
  include UuidPrimaryKey

  OVERLAPPING_TIMES_ERROR = I18n.t('text.currency_sale.overlap_error')
  TIME_TRAVEL_FAIL = I18n.t('text.currency_sale.time_travel_fail')
  MULTIPLIER_SELECT = [1.5, 2.0, 3.0]

  belongs_to :currency

  validates_presence_of :start_time, :end_time, :multiplier
  validates_uniqueness_of :start_time, :end_time
  validates_numericality_of :multiplier, :greater_than => 0
  validate :valid_start_end, :in_the_future, :not_overlapping_times, :if => :time_changed?
  validates_each :multiplier do |record, attribute, value|
    record.errors.add(attribute, I18n.t('text.currency_sale.must_be_dropdown')) unless CurrencySale::MULTIPLIER_SELECT.include?(value)
  end
  validates_inclusion_of :message_enabled, :in => [ true, false ]

  scope :active, lambda { { :conditions => [ "start_time <= ? AND end_time > ?", Time.zone.now, Time.zone.now ] } }
  scope :past, lambda { { :conditions => [ "start_time < ? AND end_time < ?", Time.zone.now, Time.zone.now ], :order => 'start_time' } }
  scope :future, lambda { { :conditions => [ "start_time > ? AND end_time > ?", Time.zone.now, Time.zone.now ], :order => 'start_time' } }

  def past?
    now = Time.zone.now
    start_time < now && end_time < now
  end

  private

  def time_changed?
    self.start_time.present? && self.end_time.present? && [self.start_time_changed?, self.end_time_changed?].any?
  end

  def in_the_future
    now = Time.zone.now
    if start_time_changed? && end_time_changed?
      errors.add(:base, TIME_TRAVEL_FAIL) if ((now - 1.hour) >= self.start_time) || (now >= self.end_time)
    elsif start_time_changed?
      errors.add(:base, TIME_TRAVEL_FAIL) if (now - 1.hour) >= self.start_time
    elsif end_time_changed?
      errors.add(:base, TIME_TRAVEL_FAIL) if now >= self.end_time
    end
  end

  def valid_start_end
    errors.add :end_time, "must be after Start Time" if self.start_time >= self.end_time
  end

  def not_overlapping_times
    currency = Currency.find(currency_id)
    unless currency.currency_sales.blank?
      currency.currency_sales.each do |currency_sale|
        next if self.id == currency_sale.id
        check_overlapping_errors(currency_sale)
        break if errors[:base].include?(OVERLAPPING_TIMES_ERROR)
      end
    end
  end

  def check_overlapping_errors(currency_sale)
    errors.add(:base, OVERLAPPING_TIMES_ERROR) if overlapping?(currency_sale)
  end

  def overlapping?(currency_sale)
    (self.start_time <= currency_sale.start_time &&
      (self.end_time >= currency_sale.end_time ||
      (self.end_time <= currency_sale.end_time && self.end_time >= currency_sale.start_time))) ||
    (self.start_time >= currency_sale.start_time &&
      (self.end_time <= currency_sale.end_time ||
      (self.end_time >= currency_sale.end_time && self.start_time <= currency_sale.end_time)))
  end
end
