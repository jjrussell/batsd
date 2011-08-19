require 'test_helper'

class AppStoreTest < ActiveSupport::TestCase
=begin
  context "Fetching Windows Phone 7 App Details" do
    setup do
      AppStore.stubs(:request).returns(stubbed_response('app_store_windows_fetch.xml'))
    end

    should "parse app details" do
      id = 'ea9a24ad-d2d1-df11-9eae-00237de2db9e'
      expected_icon_url = 'http://catalog.zune.net/v3.2/image/6654ae46-2024-4093-88b0-6ed3ef83507f?width=160&height=120'
      app = AppStore.fetch_app_by_id_for_windows(id)
      assert_equal id, app[:item_id]
      assert_equal "Bejeweled\342\204\242 LIVE", app[:title]
      assert app[:description].length > 10
      assert_equal expected_icon_url, app[:icon_url]
      assert_equal 'PopCap Games', app[:publisher]
      assert_equal '4.99', app[:price]
      assert_equal 64688128, app[:file_size_bytes]
      assert_equal '4.26', app[:user_rating].to_s
      assert_equal '2010-10-08T00:00:00Z', app[:released_at]
      assert_equal ['Games', 'Board & Classic'], app[:categories]
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
    should "calculate equivalent price when not using USD" do
      AppStore::PRICE_TIERS.each do |currency, tiers|
        tiers.each_with_index do |price, tier|
          expected_price = 0.01 * (99 + tier * 100)
          usd_price = AppStore.recalculate_app_price('iphone', price, currency)
          assert_equal expected_price, usd_price, [price, currency].inspect
        end
      end

      assert_equal 1.99, AppStore.recalculate_app_price('iphone',  1.99, 'USD')
      assert_equal 0.99, AppStore.recalculate_app_price('iphone',  2999, 'QQQ')
      assert_equal 0.99, AppStore.recalculate_app_price('android', 2999, 'JPY')
    end
  end
end
