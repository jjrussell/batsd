require 'application_specific'
require 'uuid_primary_key'

class ConsoleSecurity::Permission < ActiveRecord::Base
  self.table_name_prefix = 'console_'

  include UuidPrimaryKey
  include ApplicationSpecific

  attr_accessible :action, :target
end
