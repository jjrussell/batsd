class PartnerChange < ActiveRecord::Base
  include UuidPrimaryKey

  SUPPORTED_TYPES = %w(App GenericOffer SurveyOffer VideoOffer)

  belongs_to :item, :polymorphic => true
  belongs_to :source_partner, :class_name => 'Partner'
  belongs_to :destination_partner, :class_name => 'Partner'

  validates_presence_of :item, :source_partner, :destination_partner
  validates_inclusion_of :item_type, :in => SUPPORTED_TYPES
  validate :source_partner_owns_item

  named_scope :to_complete, lambda { { :conditions => ["scheduled_for <= ?", Time.zone.now] } }

  def complete!
    return if completed_at?

    item.partner = destination_partner
    item.save!

    self.completed_at = Time.zone.now
    save!
  end

  private

  def source_partner_owns_item
    errors.add(:item, 'must be owned by the source partner') unless completed_at? || item.partner_id == source_partner_id
  end

end
