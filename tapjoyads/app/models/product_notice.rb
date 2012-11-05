class ProductNotice
  REDIS_KEY_FOR_MESSAGE = 'dashboard.product_notice'

  attr_reader :message

  def self.instance
    @instance ||= ProductNotice.new
  end

  def self.key
    REDIS_KEY_FOR_MESSAGE
  end

  def message=(m)
    @message = $redis.set(REDIS_KEY_FOR_MESSAGE, m)
  end

  def empty?
    message.empty?
  end

  private
  def initialize
    @message = $redis.get(REDIS_KEY_FOR_MESSAGE) || ''
  end

end
