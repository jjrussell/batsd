require 'spec_helper'

describe Offer::Rejecting do
  before :each do
    @dummy_class = Object.new
    @dummy_class.extend(Offer::Rejecting)
  end
  describe '#has_insufficient_funds?' do
    before :each do
      @currency = FactoryGirl.create(:currency)
    end
    context 'charges > 0' do
      before :each do
        @dummy_class.stub(:partner_id).and_return('partner_id')
        @dummy_class.stub(:payment).and_return(30)
      end
      context 'balance > 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(30)
        end
        subject { @dummy_class }
        it { should_not have_insufficient_funds(@currency) }
      end
      context 'balance <= 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(0)
        end
        subject { @dummy_class }
        it { should have_insufficient_funds(@currency) }
      end
    end
    context 'charges <= 0' do
      before :each do
        @dummy_class.stub(:partner_id).and_return(@currency.partner_id)
      end
      context 'balance > 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(30)
        end
        subject { @dummy_class }
        it { should_not have_insufficient_funds(@currency) }
      end
      context 'balance <= 0' do
        before :each do
          @dummy_class.stub(:partner_balance).and_return(0)
        end
        subject { @dummy_class }
        it { should_not have_insufficient_funds(@currency) }
      end
    end
  end

  describe '#has_coupon_already_pending?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.extend(Offer::Rejecting)
    end
    context 'no pending coupon for offer' do
      before :each do
        @device = FactoryGirl.create(:device)
      end
      it 'should return false' do
        @offer.has_coupon_already_pending?(@device).should == false
      end
    end
    context 'a nil device' do
      it 'should return false' do
        @offer.has_coupon_already_pending?(nil).should == false
      end
    end
    context 'there is a pending coupon for offer' do
      before :each do
        @offer.item_type = 'Coupon'
        @device = FactoryGirl.create(:device)
        @device.set_pending_coupon(@offer.id)
      end
      it 'should return true' do
        @offer.has_coupon_already_pending?(@device).should == true
      end
    end
  end

  describe '#has_coupon_offer_not_started?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.item_type = 'Coupon'
      @offer.extend(Offer::Rejecting)
    end
    context 'coupon offer has started' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should_not have_coupon_offer_not_started }
    end
    context 'coupon offer has started' do
      before :each do
        @coupon = FactoryGirl.create(:coupon, :start_date => Date.today + 2.days)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should have_coupon_offer_not_started }
    end
  end

  describe '#has_coupon_offer_expired?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @offer.item_type = 'Coupon'
      @offer.extend(Offer::Rejecting)
    end
    context 'coupon offer has expired' do
      before :each do
        @coupon = FactoryGirl.create(:coupon, :end_date => Date.today)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should have_coupon_offer_expired }
    end
    context 'coupon offer has not expired' do
      before :each do
        @coupon = FactoryGirl.create(:coupon)
        @offer.item_id = @coupon.id
      end
      subject { @offer }
      it { should_not have_coupon_offer_expired }
    end
  end

  describe '#ppe_missing_prerequisite_for_ios_reject?' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    context "action offer" do
      context "when source is tj_games" do
        before :each do
          action_offer = FactoryGirl.create(:action_offer)
          @offer = action_offer.primary_offer
          @source = "tj_games"
        end

        it "should not reject offer for android", :ppe do
          @offer.ppe_missing_prerequisite_for_ios_reject?(@source, "android").should be_false
        end

        it "should not reject offer for iphone", :ppe do
          @offer.ppe_missing_prerequisite_for_ios_reject?(@source, "iphone").should be_false
        end
      end

      context "when source is not tj_games" do
        before :each do
          action_offer = FactoryGirl.create(:action_offer)
          @offer = action_offer.primary_offer
          @offer.prerequisite_offer_id = "00001"
          @source = "offerwall"
        end

        it "should not reject offer for android", :ppe do
          @offer.ppe_missing_prerequisite_for_ios_reject?(@source, "android").should be_false
        end

        it "should not reject offer for iphone when prerequisite is present", :ppe do
          @offer.ppe_missing_prerequisite_for_ios_reject?(@source, "iphone").should be_false
        end

        it "should reject offer for iphone when prerequisite is not present", :ppe do
          @offer.prerequisite_offer_id = ''
          @offer.ppe_missing_prerequisite_for_ios_reject?(@source, "iphone").should be_true
        end
      end
    end
  end

  describe '#admin_device_required_reject?' do
    before :each do
      @offer = FactoryGirl.create(:app).primary_offer
      @device = FactoryGirl.create(:device)
      @offer.extend(Offer::Rejecting)
    end
    context 'offer requires admin device' do
      before :each do
        @offer.requires_admin_device = true     
      end
      
      it "should reject the offer when the device is not an admin device" do
        @device.last_run_time_tester = false
        @offer.admin_device_required_reject?(@device).should be_true
      end

      it "should not reject the offer when the device is an admin device" do
        @device.last_run_time_tester = true
        @offer.admin_device_required_reject?(@device).should be_false
      end
    end

    context 'offer does not require admin device' do
      before :each do
        @offer.requires_admin_device = false     
      end
      
      it "should not reject the offer when the device is not an admin device" do
        @device.last_run_time_tester = false
        @offer.admin_device_required_reject?(@device).should be_false
      end

      it "should not reject the offer when the device is an admin device" do
        @device.last_run_time_tester = true
        @offer.admin_device_required_reject?(@device).should be_false
      end
    end    
  end
end
