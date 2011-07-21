class AppMetadata < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :app_id, :store_name, :store_id
  validates_uniqueness_of :store_name, :scope => [ :app_id ]
  validates_uniqueness_of :store_id, :scope => [ :store_name ]

  belongs_to :app
  has_many :app_metadata_mappings
  has_many :apps, :through => :app_metadata_mappings
end
