require 'test_helper'

class WebRequestTest < ActiveSupport::TestCase
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
    @basic_time = Time.now.utc
    
    m = WebRequest.new
    m.put_values('connect', {:app_id => 'app1', :udid => 'udid1'}, nil, {})
    m.save
    
    m = WebRequest.new
    m.put_values('connect', {:app_id => 'app1', :udid => 'udid2'}, nil, {})
    m.add_path('new_user')
    m.save
    @basic_key = m.key
    @basic_domain = m.this_domain_name
  end
  def read_basic
    assert_equal(2, Mc.get_count(Stats.get_memcache_count_key('logins', 'app1', @basic_time)))
    assert_equal(1, Mc.get_count(Stats.get_memcache_count_key('new_users', 'app1', @basic_time)))
    
    m = WebRequest.new(:domain_name => @basic_domain, :key => @basic_key, :load => true, :load_from_memcache => false)
    assert_equal(['connect', 'new_user'], m.get('path'))
    assert_equal('app1', m.get('app_id'))
    assert_equal('udid2', m.get('udid'))
  end
  
end