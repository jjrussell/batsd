require 'spec_helper'

describe CachedOfferList do
  describe '#dynamic_domain_name' do
    it 'returns the domain name' do
      @cached_offer_list = CachedOfferList.new
      @cached_offer_list.dynamic_domain_name.should =~ /cached_offer_list_([0-9]+)/
    end
  end
end
