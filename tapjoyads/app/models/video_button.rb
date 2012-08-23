# == Schema Information
#
# Table name: video_buttons
#
#  id             :string(36)      not null, primary key
#  video_offer_id :string(36)      not null
#  name           :string(255)     not null
#  url            :string(255)
#  ordinal        :integer(4)
#  enabled        :boolean(1)      default(TRUE)
#  created_at     :datetime
#  updated_at     :datetime
#  item_id        :string(36)
#  item_type      :string(255)
#

class VideoButton < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :video_offer

  validates_presence_of :name
  validates_length_of :name, :maximum => 20, :message => "Please limit the name to 20 characters"
  validates_numericality_of :ordinal, :only_integer => true
  validate :require_tracking_item

  after_save :update_offer
  after_save :update_tracking_offer

  scope :ordered, :order => "enabled DESC, ordinal"
  scope :enabled, :conditions => { :enabled => true }

  has_tracking_offers
  delegate :item, :item_id, :item_type, :to => :tracking_offer, :allow_nil => true

  def xml_for_offer
    builder = Builder::XmlMarkup.new
    xml = builder.Button do |button|
      button.tag!("Name", name)
      button.tag!("URL", url)
    end
    xml.to_s
  end

  def reject_device_type?(device, block_rewarded=false)
    !tracking_offer.get_device_types.include?(device) ||
      (block_rewarded && rewarded_install?)
  end

  def rewarded_install?
    tracking_offer.rewarded? && tracking_item.is_a?(App)
  end

  def tracking_item_options(item)
    offer = item.is_a?(Offer) ? item : item.primary_offer
    return {} unless offer.present? && offer.rewarded?

    {
      :bid          => offer.bid,
      :payment      => offer.payment,
      :reward_value => offer.reward_value,
      :rewarded     => true
    }
  end

  def disabled?
    !enabled?
  end

  private
  def update_offer
    video_offer.update_buttons
    video_offer.cache
  end

  def update_tracking_offer
    if options = tracking_item_options(tracking_item)
      tracking_offer.update_attributes(options)
    end
  end

  def require_tracking_item
    unless tracking_offer.present?
      errors.add(:tracking_offer, 'must be selected')
      false
    else
      true
    end
  end
end
