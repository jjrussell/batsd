require 'spec_helper'

describe AppStore do
=begin
  context "Fetching Windows Phone 7 App Details" do
    before :each do
      AppStore.stubs(:request).returns(stubbed_response('app_store_windows_fetch.xml'))
    end

    it "parses app details" do
      id = 'ea9a24ad-d2d1-df11-9eae-00237de2db9e'
      expected_icon_url = 'http://catalog.zune.net/v3.2/image/6654ae46-2024-4093-88b0-6ed3ef83507f?width=160&height=120'
      app = AppStore.fetch_app_by_id_for_windows(id)
      app[:item_id].should == id
      app[:title].should == "Bejeweled\342\204\242 LIVE"
      app[:description].length.should > 10
      app[:icon_url].should == expected_icon_url
      app[:publisher].should == 'PopCap Games'
      app[:price].should == '4.99'
      app[:file_size_bytes].should == 64688128
      app[:user_rating].to_s.should == '4.26'
      app[:released_at].should == '2010-10-08T00:00:00Z'
      app[:categories].should == ['Games', 'Board & Classic']
    end
  end

  private
  def stubbed_response(fixture_name)
    path = File.expand_path("../../fixtures/#{fixture_name}", __FILE__)

    fake_response = Object.new
    fake_response.stubs(:status).returns(200)
    fake_response.stubs(:body).returns(File.read(path))

    fake_response
  end
=end

  context "Class Methods" do
    it "calculates equivalent price when not using USD" do
      AppStore::PRICE_TIERS.each do |currency, tiers|
        tiers.each_with_index do |price, tier|
          expected_price = 0.01 * (99 + tier * 100)
          usd_price = AppStore.recalculate_app_price('iphone', price, currency)
          usd_price.should == expected_price
        end
      end

      AppStore.recalculate_app_price('iphone',  1.99, 'USD').should == 1.99
      AppStore.recalculate_app_price('iphone',  2999, 'QQQ').should == 0.99
      AppStore.recalculate_app_price('android', 2999, 'JPY').should == 0.99
    end
  end
end
