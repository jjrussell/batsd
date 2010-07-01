module ActionController
  module Routing
    
    class RouteSet
      alias_method :orig_extract_request_environment, :extract_request_environment
      
      def extract_request_environment(request)
        orig_extract_request_environment(request).merge({ :host => request.host })
      end
    end
    
    class Route
      alias_method :orig_recognition_conditions, :recognition_conditions
      
      def recognition_conditions
        result = orig_recognition_conditions
        result << "conditions[:hosts].include?(env[:host])" if conditions[:hosts] && Rails.env == 'production'
        result
      end
    end
    
  end
end
