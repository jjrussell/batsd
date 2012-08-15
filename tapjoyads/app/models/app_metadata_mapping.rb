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
  validate :single_primary_metadata?, :if => :is_primary?

  def offers
    app.offers.where(:app_metadata_id => app_metadata.id).order('created_at')
  end

  def primary_offer
    is_primary? ? app.primary_offer : offers.first
  end

  def primary_rewarded_featured_offer
    offers.where(:featured => true, :rewarded => true).first
  end

  def primary_non_rewarded_featured_offer
    offers.where(:featured => true, :rewarded => false).first
  end

  def primary_non_rewarded_offer
    offers.where(:featured => false, :rewarded => false).first
  end

  private

  def single_primary_metadata?
    other_primary = app.app_metadata_mappings.where(:is_primary => true).where(['id <> ?', id]).count
    errors.add(:app, "already has primary metadata association") if other_primary > 0
  end
end
