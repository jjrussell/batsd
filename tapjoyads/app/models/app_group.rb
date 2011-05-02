class AppGroup < ActiveRecord::Base
  has_many :apps
  validates_presence_of :name
end
