class ProductNotice
  REDIS_KEY_FOR_MESSAGE = 'dashboard.product_notice'

  def self.key
    REDIS_KEY_FOR_MESSAGE
  end

  def self.most_recent
    new.force_update!
  end

  def message=(m)
    @message = set_message(m)
  end

  def message
    @message ||= get_message
  end
  alias_method :to_s, :message

  def empty?
    self.message.empty?
  end

  def force_update!
    self.message = get_message
    self
  end

  private
  def get_message
    $redis.get(self.class.key) || ''
  end

  def set_message(m)
    $redis.set(self.class.key, m)
    m
  end
end
