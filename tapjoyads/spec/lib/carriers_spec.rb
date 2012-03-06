require 'spec_helper'

describe Carriers do
  it "has brands with unique names" do
    brands = Carriers::COUNTRY_NAME_TO_CARRIER_NAME.values.map{ |v| v }.flatten
    brands.to_set.length.should == brands.length
  end

  it "has same brand names in COUNTRY_NAME_TO_CARRIR_NAME and MCC_MNC_TO_CARRIER_NAME" do
    brands_set = Carriers::MCC_MNC_TO_CARRIER_NAME.values.map{ |v| v }.to_set
    brands_set.should == Carriers::COUNTRY_NAME_TO_CARRIER_NAME.values.map{ |v| v }.flatten.to_set
  end
end
