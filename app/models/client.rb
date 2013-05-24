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

  scope :ordered_by_name, order(self.arel_table[:name])
  scope :search_by_name, lambda { |name|
    where(self.arel_table[:name].matches("%#{name}%")).ordered_by_name
  }

  before_save :update_payment_type_changed_at
  before_destroy :remove_from_partners

  def update_payment_type_changed_at
    self.payment_type_changed_at = Time.zone.now if payment_type_changed?
  end

  def payment_type=(value)
    value = nil if value.blank?
    write_attribute(:payment_type, value)
  end

  def remove_from_partners
    partners.each { |p| p.update_attributes!({ :client_id => nil }) }
  end

end
