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

  after_save :update_offer

  scope :ordered, :order => "enabled DESC, ordinal"
  scope :enabled, :conditions => { :enabled => true }

  has_tracking_offers
  delegate :item, :item_id, :item_type, :to => :tracking_offer, :allow_nil => true

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

  private
  def update_offer
    video_offer.update_buttons
  end
end
