require 'test_helper'

class DeviceAppListTest < ActiveSupport::TestCase
  
  ##
  # All tests are merged into a single test case. This is because in order to guarantee 
  # consistency, we must sleep between writes. Therefore this is set up to have all writes
  # occur in write* methods, and all reads occur in read* methods. This test simply calls 
  # the write and read methods, with a single sleep in between.
  test "all tests" do
    write_basic
    
    sleep(10)
    
    read_basic
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
  
  
end