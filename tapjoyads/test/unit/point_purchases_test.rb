require 'test_helper'

class PointPurchasesTest < ActiveSupport::TestCase

  context "A Point Purchase" do
    setup do
      app = Factory(:app, :id => '01234567-89ab-cdef-0123-456789abcdef')
      currency = Factory(:currency, :id => '01234567-89ab-cdef-0123-456789abcdef', :app => app)
      @pp = PointPurchases.new(:key => "0123456789abcdef0123456789abcdef01234567.01234567-89ab-cdef-0123-456789abcdef")
    end

    should "hash to the correct domain" do
      assert_equal 'point_purchases_1', @pp.dynamic_domain_name
      assert_equal 1469972363, @pp.key.matz_silly_hash
    end

  end

  context "A Point Purchase" do
    setup do
      app = Factory(:app)
      currency = Factory(:currency, :id => app.id, :app => app)
      @pp = PointPurchases.new(:key => "udid.#{app.id}")
      @vg = Factory(:virtual_good, :price => 1, :max_purchases => 1)
      @vg2 = Factory(:virtual_good, :price => 2, :max_purchases => 3)
    end

    teardown do
      @pp.delete_all
    end

    should "Add and spend points" do
      PointPurchases.transaction(:key => @pp.key) do |point_purchases|
        point_purchases.points = point_purchases.points + 10
      end
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(10, @pp.points)

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg.key)
      assert(success, "Should successfully purchase a virtual good")
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(9, pp.points)
      assert_equal(9, @pp.points)

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg.key)
      assert(!success, "Should not be able to purchase a virtual good more than max_purchases times.")
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(9, @pp.points)

      success, message, pp = PointPurchases.spend_points(@pp.key, 4)
      assert(success, "Should succssfully spend points")
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(5, pp.points)
      assert_equal(5, @pp.points)

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg2.key, 2)
      assert(success, "Should successfully purchase multiple virtual goods")
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(1, pp.points)
      assert_equal(1, @pp.points)

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg2.key)
      assert(!success, "Should not be able to purchase virtual goods for more than the balance")
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(1, @pp.points)

      success, message, pp = PointPurchases.spend_points(@pp.key, 4)
      assert(!success, "Should not be able to spend more than the balance")
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      assert_equal(1, @pp.points)
    end
  end

end
