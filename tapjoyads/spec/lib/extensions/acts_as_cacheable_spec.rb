require 'spec_helper'
include ActsAsCacheable

describe ActsAsCacheable do
  class Testing
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
    Testing.stub(:model_name).and_return('Testing')
  end

  describe '#find_in_cache' do
    before :each do
      @foo = Testing.new
    end

    context 'when ID is valid' do
      before :each do
        @foo.stub(:id).and_return(UUIDTools::UUID.random_create.to_s)
      end

      it 'calls Mc.get once' do
        Mc.should_receive(:get).once
        Testing.find_in_cache(@foo.id, false)
      end
    end

    context 'when ID is invalid' do
      before :each do
        @foo.stub(:id).and_return('f' * 1000)
      end

      it 'does not call Mc.get with invalid key' do
        Mc.should_not_receive(:get)
        Testing.find_in_cache(@foo.id, false)
      end
    end
  end
end
