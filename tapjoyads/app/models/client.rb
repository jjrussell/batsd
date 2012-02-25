class Client < ActiveRecord::Base
  include UuidPrimaryKey

  attr_accessor :store_id_changed

  has_many :partners

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :ordered_by_name, :order => :name

  before_destroy :delete_client_from_partners

  private

  def delete_client_from_partners
    self.partners.each do |p|
      p.client_id = nil
      p.save
    end
  end

end
