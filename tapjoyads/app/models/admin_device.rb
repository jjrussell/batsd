class AdminDevice < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :user

  validates_presence_of :udid
  validates_presence_of :description
  validates_inclusion_of :platform, :in => App::PLATFORMS.keys
  validates_uniqueness_of :udid, :description

  named_scope :platform_in, lambda { |platforms| { :conditions => [ "platform in (?)", platforms ] } }
  named_scope :ordered_by_description, :order => :description

  before_save :downcase_udid

  private

  def downcase_udid
    self.udid = udid.downcase
  end

end
