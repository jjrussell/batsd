module ReadFromSlave
  module ClassMethods
    @@use_slave_connection = false

    # Overwrite this method to only use the slave when @@use_slave_connection is true
    def slave_connection
      if @@use_slave_connection
        (@slave_model || slave_model).connection_without_read_from_slave
      else
        connection_without_read_from_slave
      end
    end

    # Overwrite this method so we can define slaves per environment
    def slave_config_for(master)
      configurations["#{Rails.env}_slave_for_#{master}"]
    end

    # This is the only way to set @@use_slave_connection to true.
    # Usage:
    # Conversion.using_slave_db do
    #   # Any SQL read queries in here will be performed by the slave
    # end
    def using_slave_db
      @@use_slave_connection = true
      yield
    ensure
      @@use_slave_connection = false
    end
  end
end
