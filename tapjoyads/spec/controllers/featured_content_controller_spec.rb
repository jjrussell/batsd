require 'spec/spec_helper'

describe Tools::FeaturedContentsController do
  before :each do
    fake_the_web
    activate_authlogic
    @admin = Factory(:admin)
    @partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    @admin.partners << @partner
    login_as(@admin)

    @generic_offer = Factory(:generic_offer, :id => FEATURED_CONTENT_GENERIC_TRACKING_OFFER_ID, :partner => @partner)
  end

  describe '#create' do
    before :each do
      @start_date = Time.zone.now - 1.day
      @end_date = Time.zone.now + 1.day

      @options = {
        :featured_content => {
          :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK],
          :platforms     => ["iphone", "ipad", "itouch"],
          :subtitle      => 'Subtitle',
          :title         => 'Title',
          :description   => 'Description',
          :start_date    => @start_date.to_s,
          :end_date      => @end_date.to_s,
          :weight        => 1,
          :offer         => Factory(:app).primary_offer,
          :author        => Factory(:employee)
        }
      }
    end

    it 'should create a new featured_content' do
      post 'create', @options

      response.session[:flash][:notice].should == 'Featured content was successfully created.'
      response.should redirect_to(tools_featured_contents_path)
    end

    it 'should reject when start_date > end_date' do
      @start_date += 5.days
      @options[:featured_content][:start_date] = @start_date.to_s
      post 'create', @options

      response.session[:flash][:error].should == 'End Date must be equal to or greater than Start Date.'
      response.should render_template('tools/featured_contents/new')
    end

    context 'platforms' do
      it 'should reject when platforms is empty' do
        @options[:featured_content][:platforms] = []
        post 'create', @options

        response.session[:flash][:error].should == "Please select at least one platform, and make sure include [#{Offer::APPLE_DEVICES.join(", ")}] for iOS platform."
        response.should render_template('tools/featured_contents/new')
      end

      it 'should reject when platforms only contain part of iOS platforms' do
        @options[:featured_content][:platforms] = ['iphone']
        post 'create', @options

        response.session[:flash][:error].should == "Please select at least one platform, and make sure include [#{Offer::APPLE_DEVICES.join(", ")}] for iOS platform."
        response.should render_template('tools/featured_contents/new')
      end
    end
  end

  describe '#destroy' do
    before :each do
      @featured_content = Factory(:featured_content)
      @featured_content.update_attributes({ :button_url => "test_url" })
      @tracking_offer_id = @featured_content.tracking_offer.id
    end

    it 'delete associated tracking offer' do
      Offer.find_by_id(@tracking_offer_id).should_not be_nil

      delete 'destroy', :id => @featured_content.id

      response.should redirect_to(tools_featured_contents_path)
      Offer.find_by_id(@tracking_offer_id).should be_nil
    end
  end
end
