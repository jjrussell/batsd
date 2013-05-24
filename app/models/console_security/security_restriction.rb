require 'application_specific'
require 'uuid_primary_key'

class ConsoleSecurity::SecurityRestriction < ActiveRecord::Base
  self.table_name_prefix = 'console_'

  include UuidPrimaryKey
  include ApplicationSpecific
  include ConsoleSecurity::PermissionGroup
  has_and_belongs_to_many :roles, :class_name => 'ConsoleSecurity::Role', :join_table => 'console_roles_console_security_restrictions', :foreign_key => 'console_security_restriction_id', :association_foreign_key => 'console_role_id'
end
