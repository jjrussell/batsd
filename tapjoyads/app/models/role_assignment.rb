class RoleAssignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_role
  
  validates_presence_of :user, :user_role
end
