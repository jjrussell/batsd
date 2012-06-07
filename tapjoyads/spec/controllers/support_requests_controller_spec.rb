require 'spec_helper'

describe SupportRequestsController do
  before :each do
    fake_the_web
    @app = Factory(:app)
    @currency = Factory(:currency)
    @udid = 'test udid'
  end

  describe '#incomplete_offers' do
    it 'should perform the proper SimpleDB query' do
      now = Time.zone.now
      Time.stub(:now).and_return(now)
      conditions = ["udid = ? and currency_id = ? and clicked_at > ? and manually_resolved_at is null", @udid, @currency.id, 30.days.ago.to_f]

      Click.should_receive(:select_all).with({ :conditions => conditions }).once.and_return([])
      get(:incomplete_offers, :app_id => @app.id, :currency_id => @currency.id, :udid => @udid)
    end
  end
end
