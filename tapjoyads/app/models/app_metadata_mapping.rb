# == Schema Information
#
# Table name: app_metadata_mappings
#
#  id              :string(36)      not null, primary key
#  app_id          :string(36)      not null
#  app_metadata_id :string(36)      not null
#

class AppMetadataMapping < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :app
  belongs_to :app_metadata

  validates_presence_of :app, :app_metadata
  validates_uniqueness_of :app_id, :scope => [ :app_metadata_id ], :message => "already has a mapping to this metadata"
  validate :single_primary_metadata?, :if => lambda { |mapping| mapping.is_primary }

  def offers
    app.offers.find(:all, :conditions => ["app_metadata_id = ?", app_metadata.id])
  end

  def primary_offer
    app.offers.find(:first, :conditions => ["app_metadata_id = ?", app_metadata.id], :order => "created_at")
  end

  def primary_rewarded_featured_offer
    app.offers.find(:first, :conditions => ["app_metadata_id = ? AND featured AND rewarded", app_metadata.id], :order => "created_at")
  end

  def primary_non_rewarded_featured_offer
    app.offers.find(:first, :conditions => ["app_metadata_id = ? AND featured AND NOT rewarded", app_metadata.id], :order => "created_at")
  end

  def primary_non_rewarded_offer
    app.offers.find(:first, :conditions => ["app_metadata_id = ? AND NOT rewarded AND NOT featured", app_metadata.id], :order => "created_at")
  end

  private

  def single_primary_metadata?
    primary_mapping = app.app_metadata_mappings.find_by_is_primary(true)
    errors.add(:app, "already has primary metadata association") if primary_mapping.present? && primary_mapping != self
  end
end
