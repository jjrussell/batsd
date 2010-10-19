require 'test_helper'

class HominidTest < Test::Unit::TestCase
  should "probably rename this file and start testing for real" do
    flunk "hey buddy, you should probably rename this file and start testing for real"
  end
  should "raise an error when accepting an API key without the datacenter prefix (-)" do
    assert_raise(ArgumentError) do
      Hominid::Base.new({ :api_key => 'this_is_wrong' })
    end    
  end
end
