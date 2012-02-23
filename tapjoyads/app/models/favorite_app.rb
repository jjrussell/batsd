class FavoriteApp < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :gamer
  belongs_to :app_metadata

  validates_presence_of :gamer, :app_metadata
end
