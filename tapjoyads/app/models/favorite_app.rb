class FavoriteApp < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :gamer
  belongs_to :app

  validates_presence_of :gamer, :app
end
