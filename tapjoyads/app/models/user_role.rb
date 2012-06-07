# == Schema Information
#
# Table name: user_roles
#
#  id         :string(36)      not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#  employee   :boolean(1)
#

class UserRole < ActiveRecord::Base
  include UuidPrimaryKey

  validates_uniqueness_of :name

  has_many :role_assignments
  has_many :users, :through => :role_assignments

  def admin?
    name == 'admin'
  end
end
