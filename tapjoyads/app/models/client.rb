# == Schema Information
#
# Table name: clients
#
#  id         :string(36)      not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#

class Client < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :partners

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  scope :ordered_by_name, :order => :name

  before_destroy :remove_from_partners

  def remove_from_partners
    partners.each { |p| p.update_attributes!({ :client_id => nil }) }
  end

end
