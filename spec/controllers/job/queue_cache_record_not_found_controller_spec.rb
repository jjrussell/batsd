require 'spec_helper'

describe Job::QueueCacheRecordNotFoundController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    @currency = FactoryGirl.create(:currency)
    Currency.stub(:find_by_id).and_return(@currency)
    @message = { :model_name => 'Currency', :id => @currency.id }.to_json
  end

  it 'should cache the currency object' do
    Currency.any_instance.should_receive(:cache)
    get(:run_job, :message => @message)
  end
end
