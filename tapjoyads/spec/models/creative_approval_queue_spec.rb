require 'spec_helper'

describe CreativeApprovalQueue do
  describe '.stale' do
    before(:each) do
      @stale = Factory(:creative_approval_queue, :created_at => 8.days.ago)
      @live = Factory(:creative_approval_queue)
    end

    it 'finds records older than one week' do
      CreativeApprovalQueue.stale.should have(1).items
      CreativeApprovalQueue.stale.should include(@stale)
      CreativeApprovalQueue.stale.should_not include(@not)
    end
  end

  context 'given a record with new creative' do
    before(:each) do
      @offer = Factory(:app).primary_offer
      @offer.update_attribute(:banner_creatives, ['320x50'])
      @approval = Factory(:creative_approval_queue, :offer => @offer)
    end

    describe '#approve!' do
      before(:each) do
        @approval.approve!
      end

      it 'adds the approved size to the offer' do
        @offer.approved_banner_creatives.should include('320x50')
      end
    end

    describe '#reject!' do
      before(:each) do
        @approval.reject!
      end

      it 'removes the rejected size from the offer' do
        @offer.banner_creatives.should_not include('320x50')
      end
    end
  end
end
