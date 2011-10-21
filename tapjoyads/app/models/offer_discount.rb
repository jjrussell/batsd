class OfferDiscount < ActiveRecord::Base
  include UuidPrimaryKey

  SOURCES = %w( Admin Spend Exclusivity )

  belongs_to :partner

  validates_presence_of :partner, :source, :expires_on, :amount
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => false
  validates_inclusion_of :source, :in => OfferDiscount::SOURCES, :allow_nil => false, :allow_blank => false

  named_scope :active, lambda { { :conditions => [ "expires_on > ?", Time.zone.today ] } }

  after_save :recalculate_premier_discount_for_partner

  def active?
    expires_on > Time.zone.today
  end

  def deactivate!
    if source == 'Admin' && expires_on > Time.zone.today
      self.expires_on = Time.zone.today
      self.save
    else
      false
    end
  end

private

  def recalculate_premier_discount_for_partner
    partner.recalculate_premier_discount!
  end

end
