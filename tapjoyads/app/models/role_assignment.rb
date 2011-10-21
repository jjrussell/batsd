class RoleAssignment < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :user
  belongs_to :user_role

  validates_presence_of :user, :user_role
  validates_uniqueness_of :user_id, :scope => [ :user_role_id ]
end
