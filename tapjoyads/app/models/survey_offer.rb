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
  acts_as_trackable

  DEFAULT_ICON_PATH = 'icons/survey-blue.png' unless defined? DEFAULT_ICON_PATH
  DEFAULT_ICON_URL  = 'https://s3.amazonaws.com/' + BucketNames::TAPJOY + '/' + DEFAULT_ICON_PATH

  has_many :questions, :class_name => "SurveyQuestion"
  alias_method :survey_questions, :questions

  has_many :offers, :as => :item
  has_one :primary_offer,
    :class_name => 'Offer',
    :as => :item,
    :foreign_key => :item_id

  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  accepts_nested_attributes_for :questions

  validates_presence_of :partner, :name
  validates_presence_of :bid, :on => :create
  validates_presence_of :prerequisite_offer, :if => Proc.new { |survey_offer| survey_offer.prerequisite_offer_id? }
  validates_with OfferPrerequisitesValidator

  after_initialize :set_default_partner
  before_save :build_primary_offer,         :if => Proc.new { |survey_offer| survey_offer.new_record? }
  after_save :save_primary_offer

  set_callback :cache_associations, :before, :questions

  delegate :enabled?, :to => :primary_offer

  scope :visible, :conditions => { :hidden => false }
  def visible?;  not hidden? ; end
  def disabled?; not enabled?; end

  json_set_field :exclusion_prerequisite_offer_ids

  def bid
    primary_offer.try(:bid) || @bid || 0
  end

  def bid=(amount)
    @bid = amount
  end

  def icon=(io)
    @icon = io
  end

  def hide!
    offers.each(&:tapjoy_disable!)
    self.hidden = true
    save
  end

  def to_s; name; end

  def enable!
    self.enabled = true
  end

  def disable!
    self.enabled = false
  end

  def enabled=(value)
    primary_offer.user_enabled = value
    save
  end

  def question(position)
    questions.where(:position => position.to_i).first
  end

  def questions_attributes=(qs)
    questions.destroy_all
    return unless qs.present?
    position = 1
    qs.keys.sort.each do |i|
      params = qs[i]
      if params['text'].blank?
        qs.delete(i.to_i)
      else
        questions.create!(params.merge(:position => position))
        position += 1
      end
    end
  end

private

  def set_default_partner
    self.partner_id ||= TAPJOY_SURVEY_PARTNER_ID
  end

  def save_primary_offer
    has_icon                        = !primary_offer.new_record?

    primary_offer.id                = self.id
    primary_offer.partner_id        = partner_id || TAPJOY_SURVEY_PARTNER_ID
    primary_offer.name              = name
    primary_offer.hidden            = hidden
    primary_offer.price             = 0
    primary_offer.url               = generate_url
    if @bid
      primary_offer.bid             = @bid
      primary_offer.reward_value    = @bid
    else
      primary_offer.bid             ||= 0
      primary_offer.reward_value    ||= 0
    end
    primary_offer.name_suffix         = 'Survey'
    primary_offer.device_types        = Offer::ALL_DEVICES.to_json
    primary_offer.tapjoy_enabled      = true
    primary_offer.pay_per_click       = Offer::PAY_PER_CLICK_TYPES[:non_ppc]
    primary_offer.approved_sources    = %w(offerwall)
    primary_offer.multi_complete      = false
    primary_offer.save!

    if @icon
      @icon.rewind
      save_icon!(@icon.read)
    elsif !has_icon
      save_icon!(default_icon)
    end
  end

  def generate_url
    url_params = [
      "id=#{id}",
      "udid=TAPJOY_UDID",
      "click_key=TAPJOY_SURVEY",
    ]
    "#{API_URL}/survey_results/new?#{url_params.join('&')}"
  end

  def default_icon
    @default_icon ||= bucket.objects[DEFAULT_ICON_PATH].read
  end

  def bucket
    @bucket ||= S3.bucket(BucketNames::TAPJOY)
  end

end
