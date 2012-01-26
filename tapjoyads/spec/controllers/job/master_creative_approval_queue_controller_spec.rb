require 'spec/spec_helper'

describe Job::MasterCreativeApprovalQueueController do
  describe '#stale' do
    before(:each) do
      @controller.expects(:authenticate).at_least_once.returns(true)
      Factory(:creative_approval_queue, :created_at => 8.days.ago)

      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    it 'sends an email for stale approval records' do
      get :stale

      ActionMailer::Base.deliveries.size.should == 1
    end
  end
end
