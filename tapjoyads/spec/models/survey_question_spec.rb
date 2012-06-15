require 'spec_helper'

describe SurveyQuestion do
  before :each do
    FactoryGirl.create(:partner, :id => TAPJOY_PARTNER_ID)
    @survey_question = FactoryGirl.create(:survey_question)
  end

  it { should belong_to :survey_offer }

  it { should validate_presence_of :text }
  it { should validate_presence_of :format }
  it { should validate_presence_of :survey_offer }

  it 'validates format' do
    %w( select radio text ).each do |format|
      @survey_question.format = format
      @survey_question.should be_valid
    end

    %w( pizza dog door ).each do |format|
      @survey_question.format = format
      @survey_question.should_not be_valid
    end
  end

  it "has a to_s that returns it's text" do
    @survey_question.text = 'blah'
    @survey_question.to_s.should == 'blah'
  end

  it 'splits the possible responses' do
    @survey_question.possible_responses = 'a;b;c'
    @survey_question.possible_responses.should == %w( a b c )
  end
end
