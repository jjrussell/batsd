require 'spec/spec_helper'

describe Games::HomepageController do
  describe '#get_language_code' do

    before :each do
      I18n.locale = :en
    end

    after :each do
      I18n.locale = :en
      request.env["HTTP_ACCEPT_LANGUAGE"] = nil
    end

    it 'sets locale based on language code' do
      get(:index, :language_code => "de")
      I18n.locale.should == :de
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
  context "#get_app" do
    before :each do
      @good_author = Factory(:gamer)
      @stellar_author = Factory(:gamer)
      @troll_author = Factory(:gamer, :been_buried_count => 100)
      @gamer = Factory(:gamer)
      @offer = Factory(:app).primary_offer
      @good_review = Factory(:app_review, :bury_votes_count=>0, :helpful_votes_count=>10, :author=>@good_author)
      @stellar_review = Factory(:app_review, :bury_votes_count=>0, :helpful_votes_count=>100, :author=>@stellar_author)
      @good_review_by_troll_author = Factory(:app_review, :bury_votes_count=>0, :helpful_votes_count=>1, :author=>@troll_author)
      @troll_review_by_good_author = Factory(:app_review, :bury_votes_count=>100, :author=>@good_author)
      activate_authlogic
      login_as(@gamer)
      AppReview.expects(:paginate_all_by_app_metadata_id_and_is_blank).returns([@good_review, @troll_review_by_good_author, @stellar_review, @good_review_by_troll_author])
    end
    context 'troll author sees' do
      before :each do
        controller.stubs(:current_gamer).returns(@troll_author)
        get(:get_app, :id=>@offer.id)
      end
      it 'sees good review, stellar review, own troll-authored but not good-authored troll ' do
        assigns[:app_reviews].count.should == 3
        assigns[:app_reviews].should == [@stellar_review, @good_review, @good_review_by_troll_author]
      end
    end
    context 'good author viewer ' do
      before :each do
        controller.stubs(:current_gamer).returns(@good_author)
        get(:get_app, :id=>@offer.id)
      end
      it 'sees good review, stellar review, own troll review, but not good review by troll author' do
        assigns[:app_reviews].count.should == 3
        assigns[:app_reviews].should == [@stellar_review, @good_review, @troll_review_by_good_author]
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
      it 'sees good review, stellar review,  but not troll review or troll-authored review' do
        assigns[:app_reviews].count.should == 2
      end
      it 'sees stellar review before good review' do
        assigns[:app_reviews].should == [@stellar_review, @good_review]
        assigns[:app_reviews].should_not == [@good_review, @stellar_review]
      end
    end
  end
end
