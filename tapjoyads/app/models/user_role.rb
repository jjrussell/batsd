class UserRole < ActiveRecord::Base
  include UuidPrimaryKey

  validates_uniqueness_of :name

  has_many :role_assignments
  has_many :users, :through => :role_assignments
end
