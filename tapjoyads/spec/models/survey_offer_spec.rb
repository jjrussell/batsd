require 'spec_helper'

describe SurveyOffer do
  let(:partner) { FactoryGirl.create(:partner, :id => TAPJOY_SURVEY_PARTNER_ID) }
  subject { partner; FactoryGirl.create(:survey_offer, :partner => partner) }
  let(:primary_offer) { subject.primary_offer }

  it { should have_many :questions }
  it { should have_many :offers }
  it { should have_one :primary_offer }
  it { should belong_to :partner }

  it { should validate_presence_of :name }

  it { should accept_nested_attributes_for :questions }

  context '(on create)' do
    it 'validates the presence of #bid' do
      FactoryGirl.build(:survey_offer, :bid => nil).should_not be_valid
    end

    it 'assigns a Partner' do
      subject.partner.should be_present
    end

    it { should_not be_enabled }
    it { should be_visible }
  end

  context '(after create)' do
    it 'creates a primary Offer' do
      subject.primary_offer.should be_present
    end

    it 'is not pay-per-click' do
      subject.primary_offer.should_not be_pay_per_click
    end
  end

  context '(on update)' do
    let(:another_partner) { FactoryGirl.create(:partner, :id => UUIDTools::UUID.random_create.to_s) }
    let(:bid) { rand(10) + 1 }

    before(:each) do
      subject.update_attributes({
        :partner => another_partner,
        :name => FactoryGirl.generate(:name),
        :hidden => true,
        :bid => bid
      })
      subject.reload
    end

    it 'propagates changes to #partner to the primary Offer' do
      primary_offer.partner.should == another_partner
    end

    it 'propagates changes to #name to the primary Offer' do
      primary_offer.name.should == subject.name
    end

    it 'synchronizes changes to #hidden with the primary Offer' do
      primary_offer.reload
      primary_offer.should be_hidden
    end

    it 'propagates changes to #bid to the priamry Offer' do
      primary_offer.bid.should == subject.bid
    end
  end

  describe '#questions' do
    let(:question_count) { 3 }
    before(:each) do
      question_count.times.map do
        FactoryGirl.create(:survey_question, :survey_offer => subject)
      end
      subject.reload
    end
    it 'are ordered by position' do
      positions = subject.questions.map(&:position)
      (0...question_count).each do |i|
        positions[i].should == i+1
      end
    end
  end

  describe '#questions_attributes=' do
    let(:question) { FactoryGirl.create(:survey_question, :survey_offer => subject) }
    let(:valid_question_attributes) do
      {
        'text' => "#{FactoryGirl.generate(:name)}?",
        :id => question.id,
        :format => 'text'
      }
    end

    it 'creates valid questions' do
      subject.questions_attributes = { 1 => valid_question_attributes }
      subject.questions.should be_present
    end

    it 'removes questions with blank text' do
      subject.questions_attributes = { 1 => { 'text' => '', :id => question.id } }
      subject.save
      subject.reload
      subject.questions.should be_blank
    end

    it 'requires manually ordering questions' do
      expect{ subject.questions << valid_question_attributes }.to raise_error
    end
  end

  describe '#primary_offer' do

    describe '(by default)' do
      it 'is available for all device types' do
        primary_offer.device_types == Offer::ALL_DEVICES
      end

      it 'is tapjoy_enabled' do
        primary_offer.should be_tapjoy_enabled
      end

      it 'is user_enabled' do
        primary_offer.should_not be_user_enabled
      end

      it 'is not enabled' do
        primary_offer.should_not be_enabled
      end

      it 'creates an icon' do
        primary_offer.icon_id.should be_present
      end

    end

    it 'assigns #id from the SurveyOffer' do
      primary_offer.id.should == subject.id
    end

    it 'assigns #item from the SurveyOffer' do
      primary_offer.item.should == subject
    end

    it 'assigns #partner from the SurveyOffer' do
      primary_offer.partner.should == subject.partner
    end

    it 'assigns #name from the SurveyOffer' do
      primary_offer.name.should == subject.name
    end

    it 'assigns #user_enabled from the SurveyOffer' do
      fail if primary_offer.user_enabled?
      subject.enable!
      primary_offer.should be_user_enabled
    end

    it 'assigns #reward_value to the bid value by default' do
      primary_offer.reward_value.should == primary_offer.bid
    end

    it 'assigns #price to 0 by default' do
      primary_offer.price.should == 0
    end

    describe '#url' do
      let(:params) { CGI::parse(primary_offer.url.split('?').last) }

      it 'has the SurveyOffer\'s ID as a param' do
        params['id'].first.should == subject.id
      end

      it 'has a tapjoy_device_id param of TAPJOY_DEVICE_ID' do
        params['tapjoy_device_id'].first.should == 'TAPJOY_DEVICE_ID'
      end

      it 'has a click_key param of TAPJOY_SURVEY' do
        params['click_key'].first.should == 'TAPJOY_SURVEY'
      end
    end
  end

  describe '#enabled?' do
    it 'is read from the primary Offer' do
      primary_offer = mock('Primary offer')
      primary_offer.should_receive(:enabled?).and_return(true)
      subject.stub(:primary_offer).and_return(primary_offer)
      subject.enabled?
    end
  end

  describe '#hide!' do
    it 'sets #hidden? to true' do
      subject.hide!
      subject.should be_hidden
    end

    it 'sets #tapjoy_enabled? to false on the primary offer' do
      subject.hide!
      subject.primary_offer.should_not be_tapjoy_enabled
    end
  end

  describe '.visible' do
    it 'is a scope' do
      described_class.should respond_to :visible
    end
  end

  describe '#to_s' do
    it 'is aliased to #name' do
      subject.to_s.should == subject.name
    end
  end

  describe '#icon=' do
    let(:data) { mock('Icon Data')}
    let(:icon) { mock('Icon', :rewind => nil, :read => data) }

    it 'calls save_icon! on save' do
      subject.should_receive(:save_icon!).with(data)
      subject.icon = icon
      subject.save
    end
  end

end
