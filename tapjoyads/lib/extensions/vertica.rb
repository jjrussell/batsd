module Vertica
  class Connection
    def initialize(options = {})
      reset_values

      @options = options
      @notices = []

      unless options[:skip_startup]
        connection.write Messages::Startup.new(@options[:user], @options[:database]).to_bytes
        process
      end
    end
  end
end
