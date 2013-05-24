module ActiveRecordDisabler
  class QueriesDisabled < RuntimeError; end
  
  def self.disable_queries!
    return if queries_disabled?
    Rails.logger.debug "ActiveRecordDisabler -- disabling queries"

    class << ActiveRecord::Base.connection
      [:select, :insert_sql, :update_sql, :delete_sql].each do |m|
        # Save original implementation for later
        alias_method :"__orig_#{m}", m

        # Define the method to raise a RuntimeError
        define_method(m) do
          raise ActiveRecordDisabler::QueriesDisabled.new(
            "Queries Disabled to simulate production.  See https://github.com/Tapjoy/tapjoyserver/wiki/ActiveRecordDisabler"
          )
        end
      end
    end

    ar_base_connection_metaclass.instance_variable_set(:@queries_disabled, true)
  end

  def self.enable_queries!
    return unless queries_disabled?
    Rails.logger.debug "ActiveRecordDisabler -- enabling queries"

    class << ActiveRecord::Base.connection
      [:select, :insert_sql, :update_sql, :delete_sql].each do |m|
        # Use the original implementation
        alias_method m, :"__orig_#{m}"

        # Clean up after ourselves
        remove_method :"__orig_#{m}"
      end
    end

    ar_base_connection_metaclass.instance_variable_set(:@queries_disabled, false)
  end

  def self.with_queries_enabled(&block)
    return unless block.is_a?(Proc)

    # Enable queries if they weren't
    was_disabled = queries_disabled?
    enable_queries!

    # Call the block
    val = block.call

    # Disable queries if we just enabled them
    disable_queries! if was_disabled

    # Return the value
    val
  end

  def self.queries_disabled?
    ar_base_connection_metaclass.instance_variable_get(:@queries_disabled)
  end

  def self.ar_base_connection_metaclass
    class << ActiveRecord::Base.connection; self; end
  end
end
