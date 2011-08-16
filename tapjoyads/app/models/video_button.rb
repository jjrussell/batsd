class VideoButton < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :video_offer
  
  validates_presence_of :url, :name
  validates_numericality_of :ordinal, :only_integer => true
  
  after_save :update_offer
  
  named_scope :ordered, :order => "enabled DESC, ordinal"
  named_scope :enabled_buttons, :conditions => { :enabled => true }
  
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
    video_offer = VideoOffer.find(video_offer_id)
    video_offer.update_buttons
  end
end