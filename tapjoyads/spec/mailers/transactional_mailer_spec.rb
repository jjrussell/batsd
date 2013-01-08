require 'spec_helper'

describe TransactionalMailer do
  before :each do
    @mailer = TransactionalMailer.new
    device = FactoryGirl.create(:device)
    Device.stub(:find).and_return(device)
  end

  ##
  ## TODO: Spec out setup_for_tjm_welcome_email
  ##

  ##
  ## TODO: Spec out build_data_for_tjm_welcome_email
  ##

  describe '#welcome_email' do
    before :each do
      @gamer = FactoryGirl.create(:gamer)
    end

    context 'when a gamer with an invalid email address' do
      before :each do
        @gamer.email = 'invalid@tapjoyed.com'
        @gamer.save
      end

      around :each do |example|
        VCR.use_cassette('exact_target/send_triggered_email/invalid_email') do
          example.run
        end
      end

      it "it sets the email_invalid flag on the gamer" do
        @mailer.welcome_email(@gamer)
        @gamer.email_invalid.should be_true
      end
    end

    context 'when a gamer has a valid email address' do
      around :each do |example|
        VCR.use_cassette('exact_target/send_triggered_email/valid_email') do
          example.run
        end
      end

      it "doesn't set the email_invalid flag on gamer" do
        @mailer.welcome_email(@gamer)
        @gamer.email_invalid.should_not be_true
      end
    end
  end

  describe '#post_confirm_email' do
    before :each do
      @gamer = FactoryGirl.create(:gamer)
    end

    context 'when a gamer with an invalid email address' do
      before :each do
        @gamer.email = 'invalid@tapjoyed.com'
        @gamer.save
      end

      around :each do |example|
        VCR.use_cassette('exact_target/send_triggered_email/invalid_email') do
          example.run
        end
      end

      it "it sets the email_invalid flag on the gamer" do
        @mailer.post_confirm_email(@gamer)
        @gamer.email_invalid.should be_true
      end
    end

    context 'when a gamer has a valid email address' do
      around :each do |example|
        VCR.use_cassette('exact_target/send_triggered_email/valid_email') do
          example.run
        end
      end

      it "doesn't set the email_invalid flag on gamer" do
        @mailer.welcome_email(@gamer)
        @gamer.email_invalid.should_not be_true
      end
    end
  end

  context '#setup_for_tjm_welcome_email_without_using_tjm_tables' do
    let(:gamer) { {
        :facebook_id => 'gamer.facebook_id',
        :email => 'gamer.email',
        :gamer_devices => [{ :type => 'iphone', :id => 'iphone_id' }, { :type => 'android', :id => 'android_id' }]
    } }
    let(:device_info) { {
        :accept_language_str => 'request.accept_language',
        :user_agent_str => 'request.user_agent',
        :device_type => 'device_type',
        :selected_devices => 'default_platform',
        :geoip_data => 'geoip_data',
        :os_version => 'os_version'
    } }
    let(:a_device) { Factory.create(:device).tap { |x| x.stub(:recommendations => [:test_value]) } }

    before :each do
      ExternalPublisher.stub(:load_all_for_device => [double('extpub', :last_run_time => 5, :get_offerwall_url => 'test_url', :currencies => [{ :id => 'curr_id' }]), double('extpub', :last_run_time => 4)])
      Downloader.stub(:get => double('response', :status => 200, :body => '{"test_k":"test_v"}'))
      subject.stub(:get_device => a_device)
    end
    it 'should assign proper instance_variables' do
      subject.should_receive(:get_latest_device)
      subject.send(:setup_for_tjm_welcome_email, gamer, device_info)
      subject.instance_variable_get(:@linked).should be_true
      subject.instance_variable_get(:@recommendations).should == [:test_value]
      subject.instance_variable_get(:@facebook_signup).should be_true
      subject.instance_variable_get(:@gamer_email).should == 'gamer.email'
      subject.instance_variable_get(:@offer_data).should_not be_nil
     end

    it 'should handle nil gamer_devices' do
      gamer[:gamer_devices] = nil
      subject.should_not_receive(:get_latest_device)
      subject.send(:setup_for_tjm_welcome_email, gamer, device_info)
      subject.instance_variable_get(:@linked).should be_false
      subject.instance_variable_get(:@recommendations).should == [:test_value]
      subject.instance_variable_get(:@facebook_signup).should be_true
      subject.instance_variable_get(:@gamer_email).should == 'gamer.email'
      subject.instance_variable_get(:@offer_data).should_not be_nil
    end

  end
  context '#record_invalid_email without using tjm_tables' do
    context 'should result in a Downloader post with proper params' do
      let(:gamer){
        {:email => 'blah@tapjoyed.com'}.tap{|g| g.stub(:email => g[:email])}
      }
      let(:signed_hash){{'test_signed'=> 'wakka wakka'}}
      before :each do
        subject.stub(:sign! => signed_hash)
      end
      it 'should call post_invalid_email_to_tjm with proper params' do
        subject.should_receive(:post_invalid_email_to_tjm).with(signed_hash)
        subject.send :record_invalid_email, gamer
      end
      it 'should result in a Downloader post with proper params' do
        Downloader.should_receive(:post).and_return(double('response',:status=>202))
        subject.send :record_invalid_email, gamer
      end
      it 'should queue into SQS if Downloader fails' do
        Downloader.should_receive(:post).and_return(double('response',:status=>500))
        Downloader.should_receive(:queue_with_retry_until_successful)
        subject.send :record_invalid_email, gamer
      end
    end
  end
end
