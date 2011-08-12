class VideoButton < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :video_offer
  
  validates_presence_of :url, :name
  validates_numericality_of :ordinal, :only_integer => true

  def xml_for_offer
    builder = Builder::XmlMarkup.new
    xml = builder.Button do |button|
      button.tag!("Name", name)
      button.tag!("URL", url)
    end
    xml.to_s
  end
end