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
      Time.stubs(:now).returns(now)
      conditions = ["udid = ? and currency_id = ? and clicked_at > ? and manually_resolved_at is null", @udid, @currency.id, 30.days.ago.to_f]

      Click.expects(:select_all).with({ :conditions => conditions }).once.returns([])
      get(:incomplete_offers, :app_id => @app.id, :currency_id => @currency.id, :udid => @udid)
    end
  end
end
