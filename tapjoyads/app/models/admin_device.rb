# == Schema Information
#
# Table name: admin_devices
#
#  id               :string(36)      not null, primary key
#  udid             :string(255)
#  tapjoy_device_id :string(255)
#  description      :string(255)
#  platform         :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  user_id          :string(36)
#

class AdminDevice < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :user

  validates_presence_of :tapjoy_device_id
  validates_presence_of :description
  validates_inclusion_of :platform, :in => App::PLATFORMS.keys
  validates_uniqueness_of :tapjoy_device_id, :description

  scope :platform_in, lambda { |platforms| { :conditions => [ "platform in (?)", platforms ] } }
  scope :ordered_by_description, :order => :description

  before_save :downcase_udid

  def tapjoy_device_id
    read_attribute('tapjoy_device_id') || udid.downcase
  end

  private

  def downcase_udid
    self.udid = udid.downcase if udid.present?
  end

end
