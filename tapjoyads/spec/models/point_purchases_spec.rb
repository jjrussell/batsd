require 'spec_helper'

describe PointPurchases do
  before :each do
    #fake_the_web
  end

  context "A Point Purchase" do
    before :each do
      app = Factory(:app, :id => '01234567-89ab-cdef-0123-456789abcdef')
      currency = Factory(:currency, :id => '01234567-89ab-cdef-0123-456789abcdef', :app => app)
      @pp = PointPurchases.new(:key => "0123456789abcdef0123456789abcdef01234567.01234567-89ab-cdef-0123-456789abcdef")
    end

    it "hashes to the correct domain" do
      @pp.dynamic_domain_name.should == 'point_purchases_1'
      @pp.key.matz_silly_hash.should == 1469972363
    end

  end

  context "A Point Purchase" do
    before :each do
      app = Factory(:app)
      currency = Factory(:currency, :id => app.id, :app => app)
      @pp = PointPurchases.new(:key => "udid.#{app.id}")
      @vg = Factory(:virtual_good, :price => 1, :max_purchases => 1)
      @vg2 = Factory(:virtual_good, :price => 2, :max_purchases => 3)
    end

    after :each do
      @pp.delete_all
    end

    it "adds and spends points" do
      PointPurchases.transaction(:key => @pp.key) do |point_purchases|
        point_purchases.points = point_purchases.points + 10
      end
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      @pp.points.should == 10

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg.key)
      success.should be_true
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      pp.points.should == 9
      @pp.points.should == 9

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg.key)
      success.should be_false
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      @pp.points.should == 9

      success, message, pp = PointPurchases.spend_points(@pp.key, 4)
      success.should be_true
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      pp.points.should == 5
      @pp.points.should == 5

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg2.key, 2)
      success.should be_true
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      pp.points.should == 1
      @pp.points.should == 1

      success, message, pp = PointPurchases.purchase_virtual_good(@pp.key, @vg2.key)
      success.should be_false
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      @pp.points.should == 1

      success, message, pp = PointPurchases.spend_points(@pp.key, 4)
      success.should be_false
      @pp = PointPurchases.new(:key => @pp.key, :consistent => true)
      @pp.points.should == 1
    end
  end

end
