module Curbit
  module Controller
    module ClassMethods
      alias_method :orig_rate_limit, :rate_limit

      def rate_limit(method, opts)
        if Rails.env.production?
          orig_rate_limit(method, opts)
        end
      end

    end
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
