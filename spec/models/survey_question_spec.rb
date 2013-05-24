require 'spec_helper'

describe SurveyQuestion do
  subject { FactoryGirl.create(:survey_question) }
  let!(:partner) {FactoryGirl.create(:partner, :id => TAPJOY_SURVEY_PARTNER_ID)}

  it { should belong_to :survey_offer }
  it { should validate_presence_of :text }
  it { should validate_presence_of :format }
  it { should validate_presence_of :survey_offer }

  describe '#format' do
    ['select', 'radio', 'text'].each do |f|
      it "allows #{f}" do
        subject.format = f
        subject.should be_valid
      end
    end

    it 'does not allow formats other than select, radio and text' do
      subject.format = 'bad format'
      subject.should_not be_valid
    end
  end

  describe '#to_s' do
    it 'is aliased to #text' do
      subject.to_s.should == subject.text
    end
  end

  describe '#responses' do
    it 'splits on ";"' do
      subject.responses = 'a;b;c'
      subject.responses.should == ['a', 'b', 'c']
    end
  end

  describe '#position' do
    it 'is automatically assigned upon create' do
      subject.position.should be_present
    end
    it 'is automatically incremented according to the number of questions the survey offer has' do
      question = FactoryGirl.create(:survey_question, :survey_offer => subject.survey_offer)
      question.position.should == 2
    end
  end

end
