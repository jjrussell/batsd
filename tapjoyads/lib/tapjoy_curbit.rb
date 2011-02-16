include Curbit::Controller

module TapjoyCurbit
  module Curbit
    module Controller
      
      private
      
      def write_to_curbit_cache(cache_key, value, options = {})
        Mc.put(cache_key, value, false, options[:expires_in])
      end
    
      def read_from_curbit_cache(cache_key)
        Mc.get(cache_key)
      end
    
      def delete_from_curbit_cache(cache_key)
        Mc.delete(cache_key)
      end
      
    end
  end
end