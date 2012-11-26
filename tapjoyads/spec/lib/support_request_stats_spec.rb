require 'spec_helper'

describe SupportRequestStats do
  app_count = App.count
  offer_count = Offer.count

  before :each do
    @selection = []
    SupportRequest.stub(:select) do |&block|
      @selection.each { |row| block.call(row) }
    end
    SupportRequestStats.clear_cache
  end

  it 'updates last_updated' do
    now = Time.zone.now
    Timecop.freeze(now) do
      SupportRequestStats.cache_all(true)
    end
    SupportRequestStats.for_past(24)[:last_updated].should == now
    SupportRequestStats.for_past(12)[:last_updated].should == now
    SupportRequestStats.for_past( 1)[:last_updated].should == now
  end

  it 'works when there are no support requests' do
    SupportRequestStats.cache_all(true)
    stats = SupportRequestStats.for_past(24)
    stats[:udids].should == []
    stats[:offers].should == []
    stats[:publisher_apps].should == []
    stats[:total].should == 0
  end

  it 'works when there is 1 support request' do
    app_id = FactoryGirl.generate(:guid)
    @selection << FactoryGirl.create(:support_request,
                                    :updated_at => Time.zone.now - 1.hour,
                                    :app_id => app_id,
                                    :offer_id => FactoryGirl.generate(:guid),
                                    :udid => FactoryGirl.generate(:udid)
                                    )
    SupportRequestStats.cache_all(true)
    stats = SupportRequestStats.for_past(24)
    stats[:udids].should == [[@selection[0].udid, 1]]
    stats[:offers].should == [[@selection[0].offer_id, 1]]
    stats[:publisher_apps].should == [[@selection[0].app_id, 1]]
    stats[:total].should == 1
  end

  it 'sorts results properly' do
    a = FactoryGirl.generate(:guid)
    b = FactoryGirl.generate(:guid)
    c = FactoryGirl.generate(:guid)
    id_hash = { b => 40, c => 10, a => 80 }
    sorted = [ [a, 80], [b, 40], [c, 10] ]
    SupportRequestStats.send(:sort_by_most_frequently_reported, id_hash).should == sorted
  end
end
