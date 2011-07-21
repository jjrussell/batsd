class AppMetadataMapping < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :app
  belongs_to :app_metadata
  
  validates_presence_of :app, :app_metadata
  validates_uniqueness_of :app_id, :scope => [ :app_metadata_id ]
end
