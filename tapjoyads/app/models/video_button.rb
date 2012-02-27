class VideoButton < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :video_offer
  belongs_to :item, :polymorphic => true
  belongs_to :tracking_offer, :class_name => 'Offer'

  validates_presence_of :name
  validates_length_of :name, :maximum => 20, :message => "Please limit the name to 20 characters"
  validates_numericality_of :ordinal, :only_integer => true

  before_save :update_tracking_offer
  after_save :update_offer

  named_scope :ordered, :order => "enabled DESC, ordinal"
  named_scope :enabled, :conditions => { :enabled => true }

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

  def update_tracking_offer
    if tracking_offer.nil? || tracking_offer.id != item.id
      self.tracking_offer = Offer.find(item.id) || item.create_tracking_offer_for(self)
    end
  end
end
