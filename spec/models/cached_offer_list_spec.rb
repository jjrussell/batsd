require 'spec_helper'

describe CachedOfferList do
  before :each do
    @cached_offer_list = FactoryGirl.create(:cached_offer_list)
  end

  context '#save' do
    it 'syncs with s3' do
      CachedOfferList::S3CachedOfferList.stub(:sync_cached_offer_list).with(@cached_offer_list).once.and_return(true)
      @cached_offer_list.save
    end
  end
end
