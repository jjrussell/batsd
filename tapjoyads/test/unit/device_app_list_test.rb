# TO REMOVE - when all device_app_list domains have finished converting to devices domains

require 'test_helper'

class DeviceAppListTest < ActiveSupport::TestCase
  
  ##
  # All tests are merged into a single test case. This is because in order to guarantee 
  # consistency, we must sleep between writes. Therefore this is set up to have all writes
  # occur in write* methods, and all reads occur in read* methods. This test simply calls 
  # the write and read methods, with a single sleep in between.
  test "all tests" do
    write_basic
    write_conversion
    
    sleep(10)
    
    read_basic
    read_conversion
  end
  
  def write_basic
    m = DeviceAppList.new(:key => 'basic_app_list')
    m.set_app_ran('app1')
    m.set_app_ran('app2')
    m.save
    
    assert_equal(['app1', 'app2'], m.get_app_list)
    assert(m.has_app('app1'))
    assert(m.last_run_time('app2') > Time.now - 1.minute)
  end
  def read_basic
    m = DeviceAppList.new(:key => 'basic_app_list')
    assert_equal(['app1', 'app2'], m.get_app_list)
    assert(m.has_app('app1'))
    assert(m.last_run_time('app2') > Time.now - 1.minute)
    
    m.delete_all
  end
  
  def write_conversion
    lookup = DeviceLookup.new(:key => 'conversion_app_list')
    lookup.put('app_list', '1')
    lookup.save
    
    m = SimpledbResource.new(:key => 'conversion_app_list', :domain_name => 'device_app_list_1')
    m.put('app.app1', '1')
    m.put('app.app2', '2')
    m.save
  end
  def read_conversion
    m = DeviceAppList.new(:key => 'conversion_app_list')
    assert_equal(['app1', 'app2'], m.get_app_list)
    assert(m.has_app('app1'))
    assert_equal(Time.at(2), m.last_run_time('app2'))
    assert(!m.apps.nil?)
    assert(m.get('app.app1').nil?)
    m.serial_save
    
    sleep(2)
    m = DeviceAppList.new(:key => 'conversion_app_list')
    assert_equal(['app1', 'app2'], m.get_app_list)
    assert(!m.apps.nil?)
    
    m.delete_all
  end
  
end