require 'spec_helper'

describe SupportRequest do
  before :each do
    fake_the_web
    @support_request = SupportRequest.new
  end

  describe '#get_last_click' do
    it 'should perform the proper SimpleDB query' do
      udid, offer = 'test udid', Factory(:app).primary_offer
      conditions = ["udid = ? and advertiser_app_id = ? and manually_resolved_at is null", udid, offer.item_id]

      Click.expects(:select_all).with({ :conditions => conditions }).once.returns([])
      @support_request.get_last_click(udid, offer)
    end
  end

end
