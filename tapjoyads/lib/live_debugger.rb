class LiveDebugger
  DEFAULT_MAX_LOG_COUNT = 1000
  DEFAULT_DEBUG_PREFIX  = '__debug__'

  attr_reader :bucket, :max_log_count

  def initialize(bucket, opts={})
    prefix = opts[:prefix] || DEFAULT_DEBUG_PREFIX
    @bucket = prefix.to_s + bucket.to_s
    @max_log_count = opts[:max_log_count] || DEFAULT_MAX_LOG_COUNT
  end

  def message(object, name=nil)
    name ||= (object.is_a?(String) ? '' : object.class.to_s)
    "[#{Time.zone.now}]" + (name.present? ? " #{name}:" : '') + " #{object.inspect}"
  end

  def log(object, name=nil)
    $redis.rpop(bucket) if $redis.lpush(bucket, message(object, name)) > max_log_count
  end
  alias_method :<<, :log

  def all
    $redis.lrange(bucket, 0, -1)
  end
end
