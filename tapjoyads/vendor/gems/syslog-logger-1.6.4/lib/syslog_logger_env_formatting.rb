# Adds some default information to syslog messages.
# If you pass a User or Device object as the first parameter, it will log that user/device's id
# If you pass a block from a controller, it will automatically log the current user id
# If you pass a block, the class name of the block's context will be added
# 
# Examples
# logger.debug "O'Doyle Rules!" 
#     #=> [development] [DEBUG: 2008-01-25 14:16:12.12345] O'Doyle Rules!
# 
# #from within a controller...
# logger.error {"Something is messed up!"}
#     #=> [development] [ERROR: 2008-01-25 14:16:12.12345] [123] [ClassName] Something is messed up!

class SyslogLogger

    # short names for "DEBUG", "INFO", ...
    # must be ordered to correspond to severity constants defined in 
    # ActiveSupport::BufferedLogger::Severity 
    #@@log_level_names = %w( D I W E F U )
    #LOG_NAME_FIELD_WIDTH = 1

    @@log_level_names = %w( DEBUG INFO WARN ERROR FATAL UNKNOWN )
    LOG_NAME_FIELD_WIDTH = 7
    
    def add_with_formatting(severity, message = nil, progname = nil, &block)
      severity ||= Logger::UNKNOWN
      message = "[#{RAILS_ENV}] [#{@@log_level_names[severity].ljust(LOG_NAME_FIELD_WIDTH)}: #{time.strftime("%Y-%m-%d %H:%M:%S")}.#{time.usec.to_s.rjust(6, '0')}] #{message}"

      if(block)
        add_without_formatting(severity, message, progname,
          &Proc.new{g_log_formatter(severity, nil, user, &block)})
      else
        add_without_formatting(severity, message, progname)
      end
    end
    alias_method_chain :add, :formatting
    
end
