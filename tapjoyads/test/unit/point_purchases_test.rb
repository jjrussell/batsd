require 'test_helper'

class PointPurchasesTest < ActiveSupport::TestCase
  
  context "A Point Purchase" do
    setup do
      @pp = Factory.build(:point_purchase, :key => "0123456789abcdef0123456789abcdef01234567.01234567-89ab-cdef-0123-456789abcdef")
    end
    
    should "hash to the correct domain" do
      assert_equal 'point_purchases_1', @pp.dynamic_domain_name
    end
  end
  
end
