require 'spec_helper'
include ActsAsCacheable

describe ActsAsCacheable do
  class CacheableObject
    # TODO: make this less hacky
    def self.table_name; end
    def self.connection; self; end
    def self.columns(table_name)
      []
    end
    def self.after_commit(method_name, options); end

    acts_as_cacheable
  end

  before :each do
    CacheableObject.stub(:model_name).and_return('CacheableObject')
  end

  describe '#find_in_cache' do
    before :each do
      @foo = CacheableObject.new
    end

    context 'when ID is valid' do
      before :each do
        @foo.stub(:id).and_return(UUIDTools::UUID.random_create.to_s)
      end

      it 'calls Mc.get once' do
        Mc.should_receive(:get).once
        CacheableObject.find_in_cache(@foo.id, :do_lookup => false)
      end
    end

    context 'when ID is invalid' do
      before :each do
        @foo.stub(:id).and_return('f' * 1000)
      end

      it 'does not call Mc.get with invalid key' do
        Mc.should_not_receive(:get)
        CacheableObject.find_in_cache(@foo.id, :do_lookup => false)
      end
    end

    context 'throw the cache call to a queue' do
      before :each do
        @foo.stub(:id).and_return(UUIDTools::UUID.random_create.to_s)
        Mc.any_instance.stub(:distributed_get).and_return(nil)
      end

      it 'sqs should receive send_message call' do
        CacheableObject.stub(:find_by_id).and_return(nil)
        Sqs.should_receive(:send_message).with(QueueNames::CACHE_RECORD_NOT_FOUND, { :model_name => 'CacheableObject', :id => @foo.id }.to_json)
        CacheableObject.find_in_cache(@foo.id, :do_lookup => true, :queue => true)
      end
    end
  end
end
