require 'test_helper'

class AppStoreTest < ActiveSupport::TestCase

  context "Searching for Windows Phone 7 App" do
    setup do
      AppStore.stubs(:request).returns(stubbed_response('app_store_windows_search.json'))
    end

    should "parse app details" do
      apps = AppStore.search_windows_marketplace('pro chess')
      assert_equal 2, apps.length
      app = apps.first
      assert_equal "e4d2da5b-9933-490e-a207-31f7b89dec98", app[:item_id]
      assert_equal "ChessGenius", app[:title]
      assert_equal "http:\/\/files.marketplace.windowsmobile.com\/acda634c-204f-4bdd-b97b-6f86e826dd36\/LargeWebIcon.png", app[:icon_url]
      assert_equal "9.99", app[:price]
      assert_equal "Lang Software Limited", app[:publisher]
      assert_equal "4.33", app[:user_rating]
      assert_equal "Games", app[:categories]

      assert_equal "0.00", apps.last[:price]
    end
  end

  context "Fetching Windows Phone 7 App Details" do
    setup do
      AppStore.stubs(:request).returns(stubbed_response('app_store_windows_fetch.json'))
    end

    should "parse app details" do
      app = AppStore.fetch_app_by_id_for_windows('ee66d141-c4bd-4107-b8ff-0652bf27f02f')
      expected_icon_url = "http:\/\/files.marketplace.windowsmobile.com\/ee66d141-c4bd-4107-b8ff-0652bf27f02f\/LargeWebIcon.png"
      assert_equal "f7d62d88-df8d-4c17-819e-a06d43d233f9", app[:item_id]
      assert_equal "Trines Appointment & Task Mover", app[:title]
      assert_equal expected_icon_url, app[:icon_url]
      assert_equal expected_icon_url, app[:small_icon_url]
      assert_equal "2.99", app[:price]
      assert app[:description].length > 20
      assert_equal "Gydar Industries", app[:publisher]
      assert_equal 458169, app[:file_size_bytes]
      assert_equal "5.00", app[:user_rating]
      assert_equal Date.parse('Sep 22 06:06:23 -0700 2010'), app[:released_at]
      assert_equal "1.3", app[:version]
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
end
