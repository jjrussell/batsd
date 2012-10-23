require 'spec_helper'

describe TransactionalMailer do
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
    end
  end
end
