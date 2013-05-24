require 'spec_helper'

describe CachedOfferList::S3CachedOfferList do
  context '.sync_cached_offer_list' do
    it 'syncs with a cached offer list' do
      @cached_offer_list = FactoryGirl.create(:cached_offer_list)
      @cached_offer_list.offer_list = [1, 2]
      catcher = double('s3_cached_offer_list')
      catcher.should_receive(:offer_list=).with(@cached_offer_list.offer_list)
      catcher.should_receive(:generated_at=).with(@cached_offer_list.generated_at)
      catcher.should_receive(:cached_at=).with(@cached_offer_list.cached_at)
      catcher.should_receive(:cached_offer_type=).with(@cached_offer_list.cached_offer_type)
      catcher.should_receive(:source=).with(@cached_offer_list.source)
      catcher.should_receive(:memcached_key=).with(@cached_offer_list.memcached_key)
      CachedOfferList::S3CachedOfferList.stub(:new).with(:id => @cached_offer_list.id).and_return(catcher)
      CachedOfferList::S3CachedOfferList.sync_cached_offer_list(@cached_offer_list)
    end
  end
end
