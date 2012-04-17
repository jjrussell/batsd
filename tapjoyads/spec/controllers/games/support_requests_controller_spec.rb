require 'spec/spec_helper'

describe Games::SupportRequestsController do
  before :each do
    activate_authlogic
    @gamer = Factory(:gamer)
    login_as(@gamer)
    @controller.stubs(:current_gamer).returns(@gamer)
    flash.stubs(:sweep)
  end

  describe '#new' do
    it 'tracks the event based on the tracking param' do
      get('new')
      path = assigns(:tjm_request).path

      get('new', { :type => 'feedback'})
      assigns(:tjm_request).path.should == [ "#{path}_feedback" ]
    end
  end

  describe '#create' do
    before :each do
      @params = {
        :support_requests => { :content => 'test message' },
      }
    end

    it 'tracks the event based on the tracking param' do
      get('create', @params)
      path = assigns(:tjm_request).path
      get('create', @params.merge(:type => 'feedback'))
      assigns(:tjm_request).path.should == [ "#{path}_feedback" ]
    end

    it 'flashes a notice if no data is present' do
      get('create', { :support_requests => { :content => '' } })
      flash.now[:notice].should be_present
    end
  end
end
