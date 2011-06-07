require 'test_helper'

class WebRequestTest < ActiveSupport::TestCase
  should "write and read WebRequests consistently" do
    @basic_time = Time.now.utc
    
    m = WebRequest.new
    m.put_values('connect', {:app_id => 'app1', :udid => 'udid1'}, nil, {}, 'UserAgent1')
    m.serial_save
    
    m = WebRequest.new
    m.put_values('connect', {:app_id => 'app1', :udid => 'udid2'}, nil, {}, 'UserAgent2')
    m.add_path('new_user')
    m.serial_save
    @basic_key = m.key
    @basic_domain = m.this_domain_name

    assert_equal(2, Mc.get_count(Stats.get_memcache_count_key('logins', 'app1', @basic_time)))
    assert_equal(1, Mc.get_count(Stats.get_memcache_count_key('new_users', 'app1', @basic_time)))
    
    m = WebRequest.new(:domain_name => @basic_domain, :key => @basic_key, :load => true, :load_from_memcache => false, :consistent => true)
    assert_equal(['connect', 'new_user'], m.get('path'))
    assert_equal('app1', m.get('app_id'))
    assert_equal('udid2', m.get('udid'))
  end
end
