class ProductNotice
  REDIS_KEY_FOR_MESSAGE = 'dashboard.product_notice'

  def self.key
    REDIS_KEY_FOR_MESSAGE
  end

  def self.message=(m)
    $redis.set(REDIS_KEY_FOR_MESSAGE, m)
  end

  def self.message
    $redis.get(REDIS_KEY_FOR_MESSAGE) || ''
  end

  def self.empty?
    message.empty?
  end

  private
  def initialize; end

end
