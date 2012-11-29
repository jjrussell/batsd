require 'application_specific'
require 'uuid_primary_key'

class ConsoleSecurity::Role < ActiveRecord::Base
  self.table_name_prefix = 'console_'

  include UuidPrimaryKey
  include ApplicationSpecific
  has_and_belongs_to_many :security_permits, :class_name => 'ConsoleSecurity::SecurityPermit', :join_table => 'console_roles_console_security_permits', :foreign_key => 'console_role_id', :association_foreign_key => 'console_security_permit_id'
  has_and_belongs_to_many :security_restrictions, :class_name => 'ConsoleSecurity::SecurityRestriction', :join_table => 'console_roles_console_security_restrictions', :foreign_key => 'console_role_id', :association_foreign_key => 'console_security_restriction_id'

  attr_accessible :name
  validates :name, :presence => true
end
