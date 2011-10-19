class OneOffs

  PRODUCT_TYPES = {
    'iPod Touch (Original)'   => 'ipod',
    'iPod Touch (2nd Gen)'    => 'ipod',
    'iPod Touch (3rd Gen)'    => 'ipod',
    'iPod Touch (4th Gen)'    => 'ipod',
    'iPhone (Original)'       => 'iphone',
    'iPhone 3G'               => 'iphone',
    'iPhone 3G'               => 'iphone',
    'iPhone 3GS'              => 'iphone',
    'iPhone 3GS'              => 'iphone',
    'iPhone 4'                => 'iphone',
    'iPhone 4'                => 'iphone',
    'iPad'                    => 'ipad',
    'iPad 2 Wi-Fi'            => 'ipad',
    'iPad 2 3G'               => 'ipad',
    'iPad 2 3G'               => 'ipad',
    'iPhone'                  => 'iphone',
    'iPad'                    => 'ipad',
    'iPod'                    => 'ipod',
    'Android'                 => 'android'
  }


  def self.update_gamer_devices
    GamerDevice.find_each(:conditions => "device_type is null") do |device|
      if PRODUCT_TYPES[device.name].present?
        device.device_type = PRODUCT_TYPES[device.name]
        device.save!
      end
    end
  end
  
end
