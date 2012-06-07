# == Schema Information
#
# Table name: favorite_apps
#
#  id              :string(36)      not null, primary key
#  gamer_id        :string(36)      not null
#  app_metadata_id :string(36)      not null
#  created_at      :datetime
#  updated_at      :datetime
#

class FavoriteApp < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :gamer
  belongs_to :app_metadata

  validates_presence_of :gamer, :app_metadata
end
