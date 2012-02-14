class RailsCacheValue
  attr_reader :cached_at, :value
  def initialize(value)
    @value = value
    @cached_at = Time.now
  end
end

class RailsCache

  @@rails_cache = Hash.new

  class << self

    def put(key, value)
      @@rails_cache[key] = RailsCacheValue.new(value)
    end

    def get(key)
      @@rails_cache[key]
    end

    def get_and_put(key, max_age = 3.minutes, &block)
      result = get(key)
      if result.nil? || (Time.now - result.cached_at) > max_age
        value = yield
        put(key, value)
      else
        result
      end
    end

    def flush
      @@rails_cache = Hash.new
    end

  end

end
