# == Schema Information
#
# Table name: partner_changes
#
#  id                     :string(36)      not null, primary key
#  item_id                :string(36)      not null
#  item_type              :string(255)     not null
#  source_partner_id      :string(36)      not null
#  destination_partner_id :string(36)      not null
#  scheduled_for          :datetime
#  completed_at           :datetime
#  created_at             :datetime
#  updated_at             :datetime
#

class PartnerChange < ActiveRecord::Base
  include UuidPrimaryKey

  SUPPORTED_TYPES = %w(App GenericOffer SurveyOffer VideoOffer)

  belongs_to :item, :polymorphic => true
  belongs_to :source_partner, :class_name => 'Partner'
  belongs_to :destination_partner, :class_name => 'Partner'

  validates_presence_of :item, :source_partner, :destination_partner, :message => 'is unknown'
  validates_inclusion_of :item_type, :in => SUPPORTED_TYPES
  validate :source_partner_owns_item

  scope :to_complete, lambda { { :conditions => ["scheduled_for <= ? AND completed_at IS NULL", Time.zone.now] } }
  scope :for_dashboard, :order => 'created_at DESC'

  def complete!
    return if completed_at?

    item.partner = destination_partner
    item.save!

    self.completed_at = Time.zone.now
    save!
  end

  private

  def source_partner_owns_item
    errors.add(:item, 'must be owned by the source partner') if !completed_at? && (item.nil? || item.partner_id != source_partner_id)
  end

end
