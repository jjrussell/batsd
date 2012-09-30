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
  validate :app_must_have_one_primary_metadata

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

  def has_conflicting_primary_metadata?
    is_primary? && app.app_metadata_mappings.where(:is_primary => true).where(['id <> ?', id]).count > 0
  end

  def app_must_have_one_primary_metadata
    if has_conflicting_primary_metadata?
      errors.add(:app, "already has another primary metadata association")
    end
  end
end
