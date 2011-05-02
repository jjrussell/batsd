class AppGroup < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :apps
  validates_presence_of :name
end
