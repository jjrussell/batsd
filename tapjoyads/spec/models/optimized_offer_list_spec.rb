require 'spec_helper'

describe OptimizedOfferList do
  context "private methods that underlie the default lookups with relaxed constraints" do
    describe ".relaxed_constraints_keys" do
      list = OptimizedOfferList.send(:relaxed_constraints_keys, "6.0.Android.US.dollar.android")
      list.first.should == "6.0.Android.US.dollar.android"
      list.second.should == "6.0.Android..dollar.android"
      list.third.should == "6.0.Android.US..android"
      list.last.should == "6.0.Android...android"
    end

    describe ".hash_for_key" do
      hash = OptimizedOfferList.send(:hash_for_key, "6.0.Android.US.dollar.android")
      hash.should == {
        :algo_id=>"6",
       :currency_id=>"dollar",
       :is_tjm=>"0",
       :platform=>"Android",
       :country=>"US",
       :device_type=>"android"
       }
    end

    describe ".key_for_hash" do
      key = OptimizedOfferList.send :key_for_hash, :algo_id=>"6", :currency_id=>"dollar", :is_tjm=>"0",
                                    :platform=>"Android", :country=>"US", :device_type=>"android"
      key.should == "6.0.Android.US.dollar.android"
    end
  end
end
