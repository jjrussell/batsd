# == Schema Information
#
# Table name: video_offers
#
#  id         :string(36)      not null, primary key
#  partner_id :string(36)      not null
#  name       :string(255)     not null
#  hidden     :boolean(1)      default(FALSE), not null
#  video_url  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class VideoOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  acts_as_trackable :url => lambda { |ctx| video_url.present? ? video_url : nil }

  has_many :offers, :as => :item
  has_many :video_buttons
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner

  set_callback :cache_associations, :before, :cache_video_buttons_and_tracking_offers

  validates_presence_of :partner, :name
  validates_presence_of :video_url, :unless => :new_record?
  validate :video_exists, :unless => :new_record?

  before_save :update_video_url
  after_create :create_primary_offer
  after_update :update_offers

  scope :visible, :conditions => { :hidden => false }

  def update_buttons
    offers.each do |offer|
      offer.third_party_data = xml_for_buttons if valid_for_update_buttons?
      offer.save! if offer.changed?
    end
  end

  def valid_for_update_buttons?
    video_buttons.enabled.size <= 2
  end

  def available_trackable_items(selected_id=nil)
    ids_to_exclude = self.video_buttons.map { |r| r.item_id }.compact
    partner.trackable_items.reject { |r| selected_id != r.id && ids_to_exclude.include?(r.id) }
  end

  private

  def create_primary_offer
    offer              = Offer.new(:item => self)
    offer.id           = id
    offer.partner      = partner
    offer.name         = name
    offer.price        = 0
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url          = video_url if video_url.present?
    offer.bid          = offer.min_bid
    offer.name_suffix  = 'Video'
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.url = video_url if video_url_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end

  def update_video_url
    prefix = "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy"
    self.video_url = "#{prefix}/videos/src/#{id}.mp4"
  end

  def xml_for_buttons
    buttons = video_buttons.enabled.ordered
    buttons_xml = buttons.inject([]) do |result, button|
      result << button.xml_for_offer
    end
    buttons_xml.join
  end

  def video_exists
    bucket = S3.bucket(BucketNames::TAPJOY)
    obj    = bucket.objects["videos/src/#{id}.mp4"]

    errors.add :video_url, 'Video does not exist.' unless obj.exists?
  end

  private

  def cache_video_buttons_and_tracking_offers
    video_buttons.each(&:tracking_offer)
  end
end
