class Client < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :partners

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :ordered_by_name, :order => :name

  before_destroy :remove_from_partners

  def remove_from_partners
    partners.each { |p| p.update_attribute(:client_id, nil) }
  end

end
