require 'spec_helper'

describe GenericOfferClick do

  before :each do
    SimpledbResource.reset_connection
  end

  context "A Generic Offer Click" do
    before :each do
      @generic_offer_click = GenericOfferClick.new
      @generic_offer_click.save!
      @key = @generic_offer_click.id
    end

    it "should be correctly found when searched by id" do
      GenericOfferClick.find(@key, :consistent => true).should == @generic_offer_click
      GenericOfferClick.find_by_id(@key, :consistent => true).should == @generic_offer_click
      GenericOfferClick.find_all_by_id(@key, :consistent => true).first.should == @generic_offer_click
    end

    it "should be correctly found when searched by where conditions" do
      GenericOfferClick.find(:first, :where => "itemname() = '#{@key}'", :consistent => true).should == @generic_offer_click
      GenericOfferClick.find(:all, :where => "itemname() = '#{@key}'", :consistent => true).first.should == @generic_offer_click
    end
  end

  context "A Generic Offer Click" do
    before :each do
      @generic_offer_click = GenericOfferClick.new
      @key = @generic_offer_click.id
    end

    it "should not be found when it doesn't exist" do
      GenericOfferClick.find(:first, :where => "itemname() = '#{@key}'").should be_nil
    end
  end
  
  context "Mulitple new Generic Offer Clicks" do
    before :each do
      @count = GenericOfferClick.count(:consistent => true)
      @num = 5
      @num.times { GenericOfferClick.new.save! }
    end

    it "should be counted correctly" do 
      GenericOfferClick.count(:consistent => true).should == @count + @num
    end

    it "should be counted correctly per domain" do
      sum = GenericOfferClick.all_domain_names.inject(0) do |sum, name|
        sum + GenericOfferClick.count(:domain_name => name, :consistent => true)
      end
      sum.should == @count + @num
    end
  end

end
