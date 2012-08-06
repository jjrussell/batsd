require 'spec_helper'

describe FluentDataController do
  describe '#index' do
    before :each do
      @controller.should_receive(:fluent_authenticate).at_least(:once).and_return(true)
    end
    context 'invalid params' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'should return and respond with 400' do
        get(:index)
        should respond_with(400)
      end
    end

    context 'valid params' do
      before :each do
        time_zone = Time.zone
        time_now = time_zone.parse('2012-12-31 14:00:00')
        @params = {
          :date => '2012-12-31'
        }
        zone = Time.stub(:zone).and_return(time_zone)
        start_time = zone.stub(:parse).and_return(time_now)
        ApplicationController.stub(:verify_params).and_return(true)
        partner = FactoryGirl.create(:partner)
        Partner.stub(:find).and_return(partner)
        @app = FactoryGirl.create(:app)
        partner.stub(:apps).and_return([@app])
        App.stub(:find).and_return([@app])
        start_time.stub(:iso8601).and_return('2012-12-31')
        Appstats.stub(:new).and_return('test')
      end

      it 'should respond with 200' do
        get(:index, @params)
        should respond_with(200)
      end

      it 'has instance variable @date' do
        get(:index, @params)
        assigns(:date).should == '2012-12-31'
      end

      it 'has instance variable @appstats_list' do
        get(:index, @params)
        assigns(:appstats_list).should == [[@app, 'test'],[@app, 'test']]
      end
    end
  end
end
