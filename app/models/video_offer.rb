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
  include ActiveModel::Validations
  include UuidPrimaryKey
  acts_as_cacheable
  acts_as_trackable :url => lambda { |ctx| video_url.present? ? video_url : nil }

  AGE_GATING_MAP = {
    1 => 4,
    2 => 9,
    3 => 12,
    4 => 17,
    5 => 18,
    6 => 21
  }

  has_many :offers, :as => :item
  has_many :video_buttons
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  accepts_nested_attributes_for :primary_offer
  attr_accessor :primary_offer_creation_attributes
  attr_accessor :video_file

  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  set_callback :cache_associations, :before, :cache_video_buttons_and_tracking_offers

  attr_accessor :age_gating

  validates_presence_of :partner, :name
  validates_presence_of :prerequisite_offer, :if => Proc.new { |video_offer| video_offer.prerequisite_offer_id? }
  validate :video_exists
  validates_numericality_of :age_gating, :only_integer => true, :allow_blank => true, :message => "can only be whole number or empty."
  validates :x_partner_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates :x_partner_exclusion_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates_with OfferPrerequisitesValidator

  before_save :upload_video
  after_create :create_primary_offer
  after_update :update_offers

  scope :visible, :conditions => { :hidden => false }

  json_set_field :exclusion_prerequisite_offer_ids

  def update_buttons
    offers.each do |offer|
      offer.third_party_data = xml_for_buttons
      offer.save! if offer.changed?
    end
  end

  def video_buttons_for_device_type(device_type)
    block_rewarded = (Device.device_type_to_platform(device_type) == 'ios')
    video_buttons.reject do |button|
      button.disabled? ||
        (device_type.present? && button.reject_device_type?(device_type)) ||
        (block_rewarded && button.rewarded_install?)
    end.sort_by(&:ordinal)
  end

  def available_trackable_offers(selected_video_button)
    buttons   = video_buttons.reject { |vb| vb == selected_video_button }
    excluding = buttons.map { |vb| [vb.item_id, vb.app_metadata_id] }

    offers = partner.offers.not_tracking.nonfeatured.visible.trackable.order(:item_type, :name, :created_at)
    offers.reject do |offer|
      !offer.tapjoy_enabled? ||                                       # We can't show disabled offers
        excluding.include?([offer.item_id, offer.app_metadata_id]) || # Or offers already assigned to video buttons on this video offer
        offer.item.hidden? ||                                         # Hidden items should also not be shown
        (offer.app_offer? && offer.app_metadata_id.blank?) ||         # And if the app doesn't have a store assigned, hide it
        offer.item_id == self.id                                      # And finally, if the offer is this video offer we don't want to show it
    end
  end

  def has_video_button_for_store?(store_name)
    video_buttons.any? do |button|
      button.tracking_offer && button.tracking_offer.app_metadata.present? && button.tracking_offer.app_metadata.store_name == store_name
    end
  end

  def distribution_reject?(store_name)
    app_targeting? && !has_video_button_for_store?(store_name)
  end

  def get_x_partner_prerequisites
    Set.new(x_partner_prerequisites.split(';'))
  end
  memoize :get_x_partner_prerequisites

  def get_x_partner_exclusion_prerequisites
    Set.new(x_partner_exclusion_prerequisites.split(';'))
  end
  memoize :get_x_partner_exclusion_prerequisites

  private

  def create_primary_offer
    offer              = Offer.new(:item => self)
    offer.attributes   = self.primary_offer_creation_attributes if self.primary_offer_creation_attributes
    offer.id           = id
    offer.partner      = partner
    offer.name         = name
    offer.price        = 0
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url          = video_url if video_url.present?
    offer.bid          = offer.min_bid
    offer.name_suffix  = 'Video'
    offer.prerequisite_offer_id = prerequisite_offer_id
    offer.exclusion_prerequisite_offer_ids = exclusion_prerequisite_offer_ids
    offer.age_rating = age_gating
    offer.x_partner_prerequisites = x_partner_prerequisites
    offer.x_partner_exclusion_prerequisites = x_partner_exclusion_prerequisites
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.prerequisite_offer_id = prerequisite_offer_id if prerequisite_offer_id_changed?
      offer.exclusion_prerequisite_offer_ids = exclusion_prerequisite_offer_ids if exclusion_prerequisite_offer_ids_changed?
      offer.x_partner_prerequisites = x_partner_prerequisites if x_partner_prerequisites_changed?
      offer.x_partner_exclusion_prerequisites = x_partner_exclusion_prerequisites if x_partner_exclusion_prerequisites_changed?
      offer.url = video_url if video_url_changed?
      offer.hidden = hidden if hidden_changed?
      offer.age_rating = age_gating
      offer.save! if offer.changed?
    end
  end

  def xml_for_buttons
    buttons = video_buttons.enabled.ordered
    buttons_xml = buttons.inject([]) do |result, button|
      result << button.xml_for_offer
    end
    buttons_xml.join
  end

  def video_exists
    # Validate we had a video already, or provided one
    errors.add :video_file, 'No video.' unless video_file or video_url
  end

  def upload_video
    return unless video_file
    bucket = S3.bucket(BucketNames::TAPJOY)
    blob = video_file.read
    self.video_file = nil # so acts_as_cacheable doesn't save it
    hash = Digest::MD5.hexdigest(blob)
    path = "videos/src/#{id}/#{hash}.mp4"
    object = bucket.objects[path]
    object.write(:data => blob, :acl => :public_read) unless object.exists?

    if $rollout.active?(:cloudfront_video_offers, self)
      self.video_url = "#{CLOUDFRONT_URL}/#{path}"
    else
      self.video_url = "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy/#{path}"
    end
  end

  def cache_video_buttons_and_tracking_offers
    video_buttons.each do |button|
      button.tracking_offer
      button.tracking_item
    end
  end
end
