require 'spec_helper'

describe Dashboard::Tools::CouponsController do
  before :each do
    activate_authlogic
    admin = FactoryGirl.create(:admin)
    @partner = FactoryGirl.create(:partner, :id => TAPJOY_PARTNER_ID)
    admin.partners << @partner
    login_as(admin)
  end

  describe '#index' do
    before :each do
      @partner = FactoryGirl.create(:partner)
      @coupon = FactoryGirl.create(:coupon, :partner_id => @partner.id)
      @coupon2 = FactoryGirl.create(:coupon, :partner_id => @partner.id)
      get(:index, :partner_id => @partner.id)
    end
    it 'should have an array of coupons' do
      assigns(:coupons).should =~ [@coupon, @coupon2]
    end
  end

  describe '#new' do
    before :each do
      Partner.stub(:find_in_cache).and_return(@partner)
      get(:new, :partner_id => @partner.id)
    end
    it 'should assign instance variable partner' do
      assigns(:partner).should == @partner
    end
  end

  describe '#create' do
    context 'valid coupons' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        Coupon.stub(:obtain_coupons).and_return([@coupon])
        @params = { :partner_id => @partner.id,
                    :price => '$0.00',
                    :instructions => 'do stuff'
                  }
        post(:create, @params)
      end
      it 'should redirects to index' do
        response.should redirect_to(tools_coupons_path(:partner_id => @partner.id))
      end
      it 'has a flash message' do
        flash[:notice].should == 'Successfully created Coupons'
      end
    end
    context 'invalid coupons' do
      before :each do
        @params = { :partner_id => @partner.id,
                    :price => '$0.00',
                    :instructions => 'do stuff'
                  }
        Coupon.stub(:obtain_coupons).and_return([])
        post(:create, @params)
      end
      it 'should redirects to index' do
        response.should redirect_to(new_tools_coupon_path(:partner_id => @partner.id))
      end
      it 'has a flash message' do
        flash[:notice].should == "All coupons have been retrieved at this time. <a href=\"#{tools_coupons_path(:partner_id => @partner.id)}\">View coupons here.</a>"
      end
    end
    context 'invalid price' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        Coupon.stub(:obtain_coupons).and_return([@coupon])
        @params = { :partner_id => @partner.id,
                    :instructions => 'do stuff'
                  }
        post(:create, @params)
      end
      it 'responds with 400 error' do
        should respond_with(400)
      end
    end
  end

  describe '#show' do
    before :each do
      @coupon = FactoryGirl.create(:coupon)
      Coupon.stub(:find_in_cache).and_return(@coupon)
      get(:show, :id => @coupon.id)
    end
    it 'should have coupon instance variable' do
      assigns(:coupon).should == @coupon
    end
    it 'responds with 200' do
      should respond_with 200
    end
    it 'renders coupons/complete template' do
      should render_template('dashboard/tools/coupons/show')
    end
  end

  describe '#edit' do
    before :each do
      @coupon = FactoryGirl.create(:coupon)
      get(:edit, :id => @coupon.id)
    end
    it 'responds with 200' do
      should respond_with 200
    end
    it 'renders coupons/edit template' do
      should render_template('dashboard/tools/coupons/edit')
    end
    it 'has coupon instance variable' do
      assigns(:coupon).should == @coupon
    end
    it 'has partner instance variable' do
      assigns(:partner).should == @coupon.partner
    end
  end

  describe '#update' do
    context 'valid update params' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        Coupon.any_instance.stub(:update_attributes).and_return(true)
        @params = { :id => @coupon.id,
                    :coupon => {
                      :price => '$0.00'
                    }
                  }
        put(:update, @params)
      end
      it 'should redirect to index' do
        response.should redirect_to(tools_coupons_path(:partner_id => @coupon.partner.id))
      end
      it 'has a notice' do
        flash[:notice].should == 'Coupon updated successfully'
      end
      it 'has coupon instance variable' do
        assigns(:coupon).should == @coupon
      end
      it 'has partner instance variable' do
        assigns(:partner).should == @coupon.partner
      end
    end
    context 'invalid update params' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        Coupon.any_instance.stub(:update_attributes).and_return(false)
        @params = { :id => @coupon.id,
                    :coupon => {
                      :price => '$0.00'
                    }
                  }
        put(:update, @params)
      end
      it 'should render edit template' do
        should render_template('dashboard/tools/coupons/edit')
      end
      it 'has a notice' do
        flash.now[:error].should == 'Problems updating coupon offer'
      end
      it 'has coupon instance variable' do
        assigns(:coupon).should == @coupon
      end
      it 'has partner instance variable' do
        assigns(:partner).should == @coupon.partner
      end
    end
  end

  describe '#destroy' do
    before :each do
      @coupon = FactoryGirl.create(:coupon)
      Coupon.any_instance.should_receive(:hide!)
      delete(:destroy, :id => @coupon.id)
    end
    it 'has coupon instance variable' do
      assigns(:coupon).should == @coupon
    end
    it 'has partner instance variable' do
      assigns(:partner).should == @coupon.partner
    end
    it 'redirects to #index' do
      response.should redirect_to(tools_coupons_path(:partner_id => @coupon.partner.id))
    end
    it 'has a flash notice' do
      flash[:notice].should == 'Coupon has been successfully removed.'
    end
  end

  describe '#toggle_enabled' do
    context 'enable coupon' do
      before :each do
        Offer.any_instance.stub(:enabled?).and_return(true)
        @coupon = FactoryGirl.create(:coupon)
        @coupon.enabled = false
        put(:toggle_enabled, :id => @coupon.id)
      end
      it 'has coupon instance variable' do
        assigns(:coupon).should == @coupon
      end
      it 'has partner instance variable' do
        assigns(:partner).should == @coupon.partner
      end
      it 'redirects to #index' do
        response.should redirect_to(tools_coupons_path(:partner_id => @coupon.partner.id))
      end
      it 'has a flash notice' do
        flash[:notice].should == 'Coupon has been enabled.'
      end
    end
    context 'disable coupon' do
      before :each do
        Offer.any_instance.stub(:enabled?).and_return(false)
        @coupon = FactoryGirl.create(:coupon)
        @coupon.enabled = true
        put(:toggle_enabled, :id => @coupon.id)
      end
      it 'has coupon instance variable' do
        assigns(:coupon).should == @coupon
      end
      it 'has partner instance variable' do
        assigns(:partner).should == @coupon.partner
      end
      it 'redirects to #index' do
        response.should redirect_to(tools_coupons_path(:partner_id => @coupon.partner.id))
      end
      it 'has a flash notice' do
        flash[:notice].should == 'Coupon has been disabled.'
      end
    end
  end
end
