class VideoButton < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :video_offer

  validates_presence_of :name
  validates_length_of :name, :maximum => 20, :message => "Please limit the name to 20 characters"
  validates_numericality_of :ordinal, :only_integer => true

  after_save :update_offer

  scope :ordered, :order => "enabled DESC, ordinal"
  scope :enabled, :conditions => { :enabled => true }

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
