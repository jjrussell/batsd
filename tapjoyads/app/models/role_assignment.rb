# == Schema Information
#
# Table name: role_assignments
#
#  id           :string(36)      not null, primary key
#  user_id      :string(36)      not null
#  user_role_id :string(36)      not null
#

class RoleAssignment < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :user
  belongs_to :user_role

  validates_presence_of :user, :user_role
  validates_uniqueness_of :user_id, :scope => [ :user_role_id ]

  delegate :admin?, :name, :to => :user_role

  def <=>(other)
    name <=> other.name
  end
end
