class AppMetadata < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :app_metadata_mappings
  has_many :apps, :through => :app_metadata_mappings

  validates_presence_of :store_name, :store_id
  validates_uniqueness_of :store_id, :scope => [ :store_name ]
end
