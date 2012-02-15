class SurveyOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  has_many :survey_questions
  has_one :offer, :as => :item
  has_one :primary_offer,
    :class_name => 'Offer',
    :as => :item,
    :foreign_key => :item_id

  belongs_to :partner

  attr_accessor :bid_price

  accepts_nested_attributes_for :survey_questions

  validates_presence_of :partner, :name
  validates_presence_of :bid_price, :on => :create

  before_validation :assign_partner_id
  after_create :create_primary_offer, :create_icon
  after_update :update_offer
  cache_associations :survey_questions

  named_scope :visible, :conditions => { :hidden => false }

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

  private

  def create_primary_offer
    url_params = [
      "id=#{id}",
      "udid=TAPJOY_UDID",
      "click_key=TAPJOY_SURVEY",
    ]
    url = "#{API_URL}/survey_results/new?#{url_params.join('&')}"
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
    })
    offer.id = id
    offer.save!
  end

  def create_icon
    reload
    bucket = S3.bucket(BucketNames::TAPJOY)
    image_data = bucket.objects['icons/survey-blue.png'].read
    primary_offer.save_icon!(image_data)
  end

  def update_offer
    offer.partner_id       = partner_id
    offer.name             = name
    offer.hidden           = hidden
    offer.bid              = @bid_price unless @bid_price.blank?
    offer.save! if offer.changed?
  end

  def assign_partner_id
    self.partner_id ||= TAPJOY_PARTNER_ID
  end
end
