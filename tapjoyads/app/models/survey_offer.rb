# == Schema Information
#
# Table name: survey_offers
#
#  id         :string(36)      not null, primary key
#  partner_id :string(36)      not null
#  name       :string(255)     not null
#  hidden     :boolean(1)      default(FALSE), not null
#  created_at :datetime
#  updated_at :datetime
#  locked     :boolean(1)      default(FALSE), not null
#

class SurveyOffer < ActiveRecord::Base
  include ActiveModel::Validations
  include UuidPrimaryKey
  acts_as_cacheable

  has_many :survey_questions
  has_one :offer, :as => :item
  has_one :primary_offer,
    :class_name => 'Offer',
    :as => :item,
    :foreign_key => :item_id

  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  attr_accessor :bid_price

  accepts_nested_attributes_for :survey_questions

  validates_presence_of :partner, :name
  validates_presence_of :bid_price, :on => :create
  validates_presence_of :prerequisite_offer, :if => Proc.new { |survey_offer| survey_offer.prerequisite_offer_id? }
  validates_with OfferPrerequisitesValidator

  before_validation :assign_partner_id
  after_create :create_primary_offer, :create_icon
  after_update :update_offer
  set_callback :cache_associations, :before, :survey_questions

  scope :visible, :conditions => { :hidden => false }

  json_set_field :exclusion_prerequisite_offer_ids

  def bid
    if @bid_price
      @bid_price
    elsif primary_offer
      primary_offer.bid
    else
      nil
    end
  end

  def bid=(price)
    @bid_price = price.to_i
  end

  def hide!
    self.hidden = true
    self.save!
  end

  def to_s
    name
  end

  def enabled?
    primary_offer.is_enabled?
  end

  def enabled=(value)
    primary_offer.user_enabled = value
    primary_offer.save!
  end

  def build_blank_questions(count = 4)
    (count - survey_questions.size).times { survey_questions.build }
  end

  alias :survey_questions_attrs= :survey_questions_attributes=

  def survey_questions_attributes=(questions_attrs)
    unless questions_attrs.nil?
      questions_attrs.each do |num, hash|
        if hash['text'].blank?
          SurveyQuestion.delete(hash[:id])
          questions_attrs.delete(num)
        end
      end
      self.survey_questions_attrs=(questions_attrs)
    end
  end

  def create_tracking_offer_for(tracked_for, options = {})
    device_types = options.delete(:device_types) { Offer::ALL_DEVICES.to_json }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    url = generate_url

    offer = Offer.new({
      :item             => self,
      :tracking_for     => tracked_for,
      :partner          => partner,
      :name             => name,
      :url              => url,
      :device_types     => device_types,
      :price            => 0,
      :bid              => 0,
      :min_bid_override => 0,
      :rewarded         => false,
      :name_suffix      => 'tracking',
    })
    offer.id = tracked_for.id
    offer.save!

    offer
  end

  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(id)}.merge(options))
  end

  def save_icon!(icon_src_blob)
    Offer.upload_icon!(icon_src_blob, id)
  end

  private

  def create_primary_offer
    url = generate_url

    offer = Offer.new({
      :item             => self,
      :partner          => partner,
      :name             => name,
      :reward_value     => 15,
      :price            => 0,
      :url              => url,
      :bid              => @bid_price,
      :name_suffix      => 'Survey',
      :device_types     => Offer::ALL_DEVICES.to_json,
      :tapjoy_enabled   => true,
      :multi_complete   => false,
      :prerequisite_offer_id => prerequisite_offer_id,
      :exclusion_prerequisite_offer_ids => exclusion_prerequisite_offer_ids,
    })
    offer.id = id
    offer.save!
  end

  def generate_url
    url_params = [
      "id=#{id}",
      "udid=TAPJOY_UDID",
      "click_key=TAPJOY_SURVEY",
    ]
    "#{API_URL}/survey_results/new?#{url_params.join('&')}"
  end

  def create_icon
    reload
    bucket = S3.bucket(BucketNames::TAPJOY)
    image_data = bucket.objects['icons/survey-blue.png'].read
    save_icon!(image_data)
  end

  def update_offer
    offer.partner_id       = partner_id
    offer.name             = name
    offer.hidden           = hidden
    offer.bid              = @bid_price unless @bid_price.blank?
    offer.prerequisite_offer_id = prerequisite_offer_id
    offer.exclusion_prerequisite_offer_ids = exclusion_prerequisite_offer_ids
    offer.save! if offer.changed?
  end

  def assign_partner_id
    self.partner_id ||= TAPJOY_PARTNER_ID
  end
end
