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
    'iPad1,1'    => 'iPad',
    'iPad2,1'    => 'iPad 2 Wi-Fi',
    'iPad2,2'    => 'iPad 2 3G',
    'iPad2,3'    => 'iPad 2 3G',
  }
  PRODUCT_NAMES.default = 'My Device'
  
  belongs_to :gamer
  
  validates_presence_of :gamer, :device_id, :name
  
  def product=(product)
    self.name = PRODUCT_NAMES[product]
  end
  
  def device=(device)
    self.device_id = device.id
    self.product = device.product
  end
end
