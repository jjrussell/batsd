require 'test_helper'

class DisplayAdControllerTest < ActionController::TestCase
  
  context "hitting display ad controller" do
    setup do
      RailsCache.stubs(:get).returns(nil)
      @offer = Factory(:app).primary_offer
      @offer.name = "Consistent Name"
      Offer.stubs(:find_in_cache).with(@offer.id).returns(@offer)
      OfferCacher.stubs(:get_unsorted_offers_prerejected).returns([@offer])
    
      @bucket = S3.bucket(BucketNames::TAPJOY)
      S3.stubs(:bucket).with(BucketNames::TAPJOY).returns(@bucket)
    
      @currency = Factory(:currency)
      @params = { :udid => 'stuff', :publisher_user_id => 'more_stuff', :currency_id => @currency.id, :app_id => @currency.app.id }
    end
  
    context "when calling 'image'" do
      setup do
        @params.merge!(:advertiser_app_id => @offer.id, :size => '320X50', :publisher_app_id => @params[:app_id])
        @params.delete(:app_id)
      end
    
      context "with custom ad" do
        setup do
          @offer.banner_creatives = %w(320x50)
          @offer.rewarded = false
      
          s3key = RightAws::S3::Key.create(@bucket, @offer.banner_creative_path('320x50'))
          RightAws::S3::Key.stubs(:create).with(@bucket, @offer.banner_creative_path('320x50')).returns(s3key)
          @custom_banner = File.open("#{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png").read
          s3key.stubs(:get).returns(@custom_banner)
        end
      
        should "return proper image" do
          response = get(:image, @params)
          assert_equal('image/png', response.content_type)
        
          assert(@custom_banner == response.body)
        end
      end
    
      context "with generated ad" do
        setup do
          ad_bg = File.open("#{RAILS_ROOT}/test/assets/display/self_ad_bg_320x50.png").read
          td_icon = File.open("#{RAILS_ROOT}/test/assets/icons/tap_defense.jpg").read
          round_mask = File.open("#{RAILS_ROOT}/test/assets/display/round_mask.png").read
          icon_shadow = File.open("#{RAILS_ROOT}/test/assets/display/icon_shadow.png").read
          
          @bucket.stubs(:get).with("display/self_ad_bg_320x50.png").returns(ad_bg)
          @bucket.stubs(:get).with("icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg").returns(td_icon)
          @bucket.stubs(:get).with("display/round_mask.png").returns(round_mask)
          @bucket.stubs(:get).with("display/icon_shadow.png").returns(icon_shadow)
          
          @generated_banner = File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png").read
        end
        
        should "return proper image" do
          response = get(:image, @params)
          assert_equal('image/png', response.content_type)
          
          # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
          # File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png", 'w') { |f| f.write(response.body) }
          
          assert(@generated_banner == response.body)
        end
      end
    end
    
    context "when calling 'index'" do
       context "with custom ad" do
         setup do
           @offer.banner_creatives = %w(320x50 640x100)
           @offer.rewarded = false
         end
         
         should "return proper image data in json" do
           s3key = RightAws::S3::Key.create(@bucket, @offer.banner_creative_path('320x50'))
           RightAws::S3::Key.stubs(:create).with(@bucket, @offer.banner_creative_path('320x50')).returns(s3key)
           custom_banner = File.open("#{RAILS_ROOT}/test/assets/banner_ads/custom_320x50.png").read
           s3key.stubs(:get).returns(custom_banner)
           
           response = get(:index, @params.merge(:format => 'json'))
           assert_equal('application/json', response.content_type)
           
           assert(custom_banner == Base64.decode64(assigns['image']))
         end
         
         should "return proper image data in xml" do
           s3key = RightAws::S3::Key.create(@bucket, @offer.banner_creative_path('640x100'))
           RightAws::S3::Key.stubs(:create).with(@bucket, @offer.banner_creative_path('640x100')).returns(s3key)
           custom_banner = File.open("#{RAILS_ROOT}/test/assets/banner_ads/custom_640x100.png").read
           s3key.stubs(:get).returns(custom_banner)
           
           response = get(:index, @params)
           assert_equal('application/xml', response.content_type)
           
           assert(custom_banner == Base64.decode64(assigns['image']))
         end
       end
     
       context "with generated ad" do
         setup do
           td_icon = File.open("#{RAILS_ROOT}/test/assets/icons/tap_defense.jpg").read
           round_mask = File.open("#{RAILS_ROOT}/test/assets/display/round_mask.png").read
           icon_shadow = File.open("#{RAILS_ROOT}/test/assets/display/icon_shadow.png").read
           
           @bucket.stubs(:get).with("icons/src/#{Offer.hashed_icon_id(@offer.icon_id)}.jpg").returns(td_icon)
           @bucket.stubs(:get).with("display/round_mask.png").returns(round_mask)
           @bucket.stubs(:get).with("display/icon_shadow.png").returns(icon_shadow)
         end
       
         should "return proper image data in json" do
           ad_bg = File.open("#{RAILS_ROOT}/test/assets/display/self_ad_bg_320x50.png").read
           @bucket.stubs(:get).with("display/self_ad_bg_320x50.png").returns(ad_bg)
           
           response = get(:index, @params.merge(:format => 'json'))
           assert_equal('application/json', response.content_type)
           
           # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png", 'w') { |f| f.write(Base64.decode64(assigns['image'])) }
           
           assert(File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_320x50.png").read == Base64.decode64(assigns['image']))
         end
         
         should "return proper image data in xml" do
           ad_bg = File.open("#{RAILS_ROOT}/test/assets/display/self_ad_bg_640x100.png").read
           @bucket.stubs(:get).with("display/self_ad_bg_640x100.png").returns(ad_bg)
           
           response = get(:index, @params)
           assert_equal('application/xml', response.content_type)
           
           # Uncomment the following to re-generate the image if needed (e.g. background image changes, text changes, etc)
           # File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_640x100.png", 'w') { |f| f.write(Base64.decode64(assigns['image'])) }
           
           assert(File.open("#{RAILS_ROOT}/test/assets/banner_ads/generated_640x100.png").read == Base64.decode64(assigns['image']))
         end
       end
     end
     
     context "when calling 'webview'" do
       context "with custom ad" do
         setup do
            @offer.banner_creatives = %w(320x50)
            @offer.rewarded = false
          end
         
         should "contain proper image link" do
           response = get(:webview, @params)
           
           assert_match(/^#{CLOUDFRONT_URL}/, assigns['image_url'])
           assert_equal(@offer.get_ad_image_url(@currency.app.id, 320, 50, @currency.id), assigns['image_url'])
         end
       end
       
       context "with generated ad" do
         should "contain proper image link" do
           response = get(:webview, @params)
         
           assert_match(/^#{API_URL}/, assigns['image_url'])
           assert_equal(@offer.get_ad_image_url(@currency.app.id, 320, 50, @currency.id), assigns['image_url'])
         end
       end
     end
  end
end
