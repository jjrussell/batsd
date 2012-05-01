class GamerDevice < ActiveRecord::Base
  include UuidPrimaryKey

  PRODUCT_NAMES = {
    'iPod1,1'    => 'iPod Touch (Original)',
    'iPod2,1'    => 'iPod Touch (2nd Gen)',
    'iPod3,1'    => 'iPod Touch (3rd Gen)',
    'iPod4,1'    => 'iPod Touch (4th Gen)',
    'iPhone1,1'  => 'iPhone (Original)',
    'iPhone1,2'  => 'iPhone 3G',
    'iPhone1,2*' => 'iPhone 3G',
    'iPhone2,1'  => 'iPhone 3GS',
    'iPhone2,1*' => 'iPhone 3GS',
    'iPhone3,1'  => 'iPhone 4',
    'iPhone3,3'  => 'iPhone 4',
    'iPhone4,1'  => 'iPhone 4S',
    'iPhone5,1'  => 'iPhone 5',
    'iPad1,1'    => 'iPad',
    'iPad2,1'    => 'iPad 2 Wi-Fi',
    'iPad2,2'    => 'iPad 2 3G',
    'iPad2,3'    => 'iPad 2 3G',
    'iPad3,1'    => 'iPad Wi-Fi',
    'iPad3,2'    => 'iPad 4G',
    'iPad3,3'    => 'iPad 4G',
    'iPhone'     => 'iPhone',
    'iPad'       => 'iPad',
    'iPod'       => 'iPod Touch',
    'android'    => 'Android'
  }
  PRODUCT_NAMES.default = 'My Device'

  PRODUCT_TYPES = {
    'iPod1,1'    => 'ipod',
    'iPod2,1'    => 'ipod',
    'iPod3,1'    => 'ipod',
    'iPod4,1'    => 'ipod',
    'iPhone1,1'  => 'iphone',
    'iPhone1,2'  => 'iphone',
    'iPhone1,2*' => 'iphone',
    'iPhone2,1'  => 'iphone',
    'iPhone2,1*' => 'iphone',
    'iPhone3,1'  => 'iphone',
    'iPhone3,3'  => 'iphone',
    'iPhone4,1'  => 'iphone',
    'iPhone5,1'  => 'iphone',
    'iPad1,1'    => 'ipad',
    'iPad2,1'    => 'ipad',
    'iPad2,2'    => 'ipad',
    'iPad2,3'    => 'ipad',
    'iPad3,1'    => 'ipad',
    'iPad3,2'    => 'ipad',
    'iPad3,3'    => 'ipad',
    'iPhone'     => 'iphone',
    'iPad'       => 'ipad',
    'iPod'       => 'ipod',
    'android'    => 'android'
  }

  belongs_to :gamer

  validates_presence_of :gamer, :device_id, :name
  validates_uniqueness_of :device_id, :scope => [:gamer_id]

  delegate :blocked?, :to => :gamer
  after_save :check_suspicious_activities, :unless => :blocked?

  def device=(new_device)
    self.device_id = new_device.id
    if new_device.platform == 'android'
      self.name = "Android (#{new_device.product})" if new_device.product.present?
      self.device_type = PRODUCT_TYPES[new_device.platform]
    else
      self.name = PRODUCT_NAMES[new_device.product]
      self.device_type = PRODUCT_TYPES[new_device.product]
    end
  end

  def device_data
    data = { :udid => device_id, :id => id, :device_type  => device_type }
    {
      :name        => name,
      :device_type => device_type,
      :data        => ObjectEncryptor.encrypt(data),
    }
  end

  # For use within TJM (since dashboard URL helpers aren't available within TJM)
  def dashboard_device_info_tool_url
    "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}" <<
      "/tools/device_info?udid=#{self.device_id}"
  end

  private

  def check_suspicious_activities
    devices_count = gamer.devices.count
    if gamer.too_many_devices? && devices_count % 5 == 0
      message = {
        :gamer_id        => gamer_id,
        :behavior_type   => 'devices_count',
        :behavior_result => devices_count,
      }
      Sqs.send_message(QueueNames::SUSPICIOUS_GAMERS, message.to_json)
    end
  end
end
