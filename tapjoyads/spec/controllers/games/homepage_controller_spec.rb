require 'spec_helper'

describe Games::HomepageController, :type=>:controller do
  before :each do
    fake_the_web
  end
  describe '#get_language_code' do

    before :each do
      I18n.locale = :en
    end

    after :each do
      I18n.locale = :en
      request.env["HTTP_ACCEPT_LANGUAGE"] = nil
    end

    it 'has hashes for each locale' do
      I18n.available_locales.each do |locale|
        I18n.t('hash', :locale => locale).should_not =~ /translation missing/
      end
    end

    it 'sets locale based on language code' do
      get(:index, :language_code => "de")
      I18n.locale.should == :de
    end

    it 'sets locale_filename to include hash of locale file and default locale file, for cache-busting' do
      get(:index, :language_code => "de")
      locale_filename = controller.send( :get_locale_filename )
      locale_filename.should =~ Regexp.new( I18n.t('hash').to_s + '$' )
      locale_filename.should =~ Regexp.new( I18n.t('hash', I18n.default_locale).to_s )
      locale_filename.should =~ Regexp.new( '^'+ I18n.locale.to_s + '-' )
    end

    it 'checks prefix of provided language code' do
      get(:index, :language_code => "en-XX")
      I18n.locale.should == :en
    end

    it 'sets locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "de"
      get(:index)
      I18n.locale.should == :de
    end

    it 'sets more locale based on HTTP_ACCEPT_LANGUAGE, and ignores suffix casing' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh-CN"
      get(:index)
      I18n.locale.should == :"zh-cn"
      request.env["HTTP_ACCEPT_LANGUAGE"] = "zh-sg"
      get(:index)
      I18n.locale.should == :"zh-sg"
    end

    it 'sets more locale based on language_code, and ignores suffix casing' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput!"
      get(:index, :language_code => "zh-cn")
      I18n.locale.should == :"zh-cn"
      get(:index, :language_code => "zh-SG")
      I18n.locale.should == :"zh-sg"
    end

    it 'attempts to split locale based on HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "ko-KR,es;q=0.5,zh;q=0.9"
      get(:index)
      I18n.locale.should == :ko
    end

    it 'overrides HTTP_ACCEPT_LANGUAGE with language code' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "en"
      get(:index, :language_code => "de")
      I18n.locale.should == :de
    end

    it 'sets default_locale when language_code values are invalid' do
      get(:index, :language_code => "honey badger don't care about locale")
      I18n.locale.should == I18n.default_locale
    end

    it 'sets HTTP_ACCEPT_LANGUAGE when language_code values are invalid' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "de"
      get(:index, :language_code => "honey badger don't care about locale")
      I18n.locale.should == :de
    end

    it 'sets default_locale when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput"
      get(:index)
      I18n.locale.should == I18n.default_locale
    end

    it 'sets language_code when HTTP_ACCEPT_LANGUAGE values are unacceptable' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "fake,notreal;7;totallyInvalidInput!"
      get(:index, :language_code => "de")
      I18n.locale.should == :de
    end

    it 'sets the highest available locale in HTTP_ACCEPT_LANGUAGE' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "invalid,es;q=0.5,de;q=0.9"
      get(:index)
      I18n.locale.should == :de
    end

    it 'Handles request strings w/o numbers' do
      request.env["HTTP_ACCEPT_LANGUAGE"] = "ko-KR, en-US"
      get(:index)
      I18n.locale.should == :ko
    end
  end

  describe "#index" do
    before :each do
      activate_authlogic
      @gamer = Factory(:gamer)
      login_as(@gamer)
      @controller.stub!(:current_gamer=>@gamer)
    end

    it 'creates a valid tjm_request' do
      get('index')
      tjm_request = assigns(:tjm_request)
      tjm_request.gamer_id.should == @gamer.id
    end

    context 'with a tjreferrer click as the referrer' do
      it 'records an additional tjm_request for the referral' do
        get('index', { :referrer => 'tjreferrer:abc' })
        assigns(:tjm_request)
        tjm_social_request = assigns(:tjm_social_request)
        tjm_social_request.path.should include('tjm_referrer')
      end
    end

    context 'with a facebook styled referrer' do
      it 'records the referral event' do
        facebook_referrer = "tj_fb_post_#{@gamer.id}"
        get('index', { :referrer => ObjectEncryptor.encrypt(facebook_referrer) })

        assigns(:tjm_request)
        tjm_social_request = assigns(:tjm_social_request)
        tjm_social_request.path.should include('tjm_social_referrer')
        tjm_social_request.social_referrer_gamer.should == @gamer.id
        tjm_social_request.social_source.should == 'fb'
        tjm_social_request.social_action.should == 'post'
      end
    end

    context 'with an old invitation styled referrer' do
      it 'records the referral event' do
        facebook_referrer = "TEST_INVITATION_ID,TEST_ADVERTISER_APP_ID"
        get('index', { :referrer => ObjectEncryptor.encrypt(facebook_referrer) })

        assigns(:tjm_request)
        tjm_social_request = assigns(:tjm_social_request)
        tjm_social_request.path.should include('tjm_invite_referrer')
        tjm_social_request.social_invitation_or_gamer_id.should == 'TEST_INVITATION_ID'
        tjm_social_request.social_advertiser_app_id.should == 'TEST_ADVERTISER_APP_ID'
      end
    end
  end

  describe "#record_click" do
    before :each do
      activate_authlogic
      @gamer = Factory(:gamer)
      login_as(@gamer)
      @app = Factory(:app)

      @params = {
        :eid          => ObjectEncryptor.encrypt(@app.id),
        :redirect_url => ObjectEncryptor.encrypt(@app.primary_offer.url),
      }
      get('record_click', @params)
    end

    it 'records the outbound click in a tjm_request' do
      tjm_request = assigns(:tjm_request)
      tjm_request.outbound_click_url.should == @app.primary_offer.url
      tjm_request.app_id.should == @app.id
    end

    it 'redirects to the actual app url' do
      response.should be_redirect
      response.should redirect_to(@app.primary_offer.url)
    end
  end

  context "#get_app" do
    before :each do

      @good_author = Factory(:gamer)
      @another_good_author = Factory(:gamer)
      @stellar_author = Factory(:gamer)
      @troll_author = Factory(:gamer, :been_buried_count => 100)
      @gamer = Factory(:gamer)
      @offer = Factory(:app).primary_offer
      @app_metadata = @offer.app.primary_app_metadata #Factory(:app_metadata)
      @good_review = Factory(:app_review,
                             :bury_votes_count => 0,
                             :helpful_votes_count => 10,
                             :text => "A good review",
                             :author => @good_author,
                             :app_metadata => @app_metadata)
      @stellar_review = Factory(:app_review,
                                :bury_votes_count => 0,
                                :helpful_votes_count => 100,
                                :author => @stellar_author,
                                :text => "A stellar review",
                                :app_metadata => @app_metadata)
      @good_review_by_troll_author = Factory(:app_review,
                                             :bury_votes_count => 0,
                                             :helpful_votes_count => 1,
                                             :author => @troll_author,
                                             :text => "A good review by a troll",
                                             :app_metadata => @app_metadata)
      @troll_review_by_another_good_author = Factory(:app_review,
                                                     :bury_votes_count => 100,
                                                     :text => "A troll review by a good author",
                                                     :author => @another_good_author,
                                                     :app_metadata => @app_metadata)
      activate_authlogic
      login_as(@gamer)

      #TODO(isingh): We need to move this to integration test or find a way to use stub_chain

      AppReview.stub_chain(:where, :includes, :paginate).and_return([@good_review, @troll_review_by_another_good_author, @stellar_review, @good_review_by_troll_author])
    end
    context 'troll author sees' do
      before :each do
        login_as(@troll_author)
        controller.stub(:current_gamer).and_return(@troll_author)
        get(:get_app, :id=>@offer.id)
      end
      it 'sees good review, stellar review, own troll-authored but not good-authored troll ' do
        assigns[:app_reviews].count.should == 3
        assigns[:app_reviews].should == [@stellar_review, @good_review, @good_review_by_troll_author]
      end
    end
    context 'good author viewer ' do
      before :each do
        login_as(@another_good_author)
        controller.stub!(:current_gamer=>@another_good_author)
        get(:get_app, :id=>@offer.id)
      end
      it 'sees good review, stellar review, own troll review, but not good review by troll author' do
        assigns[:app_reviews].count.should == 3
        assigns[:app_reviews].should == [@stellar_review, @good_review, @troll_review_by_another_good_author]
      end
    end
    context 'unassociated gamer viewer' do
      before :each do
        login_as(@gamer)
        controller.stub!(:current_gamer=>@gamer)
        get(:get_app, :id=>@offer.id)
      end
      it 'sees good review, stellar review,  but not troll review or troll-authored review' do
        assigns[:app_reviews].count.should == 2
      end
      it 'sees stellar review before good review' do
        assigns[:app_reviews].should == [@stellar_review, @good_review]
        assigns[:app_reviews].should_not == [@good_review, @stellar_review]
      end
    end
    context 'Guest "no login" viewer' do
      before :each do
        controller.stub(:current_gamer).and_return(nil)
      end
      it 'sees good review, stellar review,  but not troll review or troll-authored review' do
        get(:get_app, :id=>@offer.id)
        assigns[:app_reviews].count.should == 2
      end
      it 'can see a single review only if specified' do
        get(:get_app, :id=>@offer.id, :app_review_id => @stellar_review.id)
        assigns[:app_reviews].should == [@stellar_review]
      end
    end
  end
end
