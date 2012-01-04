require 'spec_helper'

describe SurveyOffer do

  it { should have_many :survey_questions }
  it { should have_one :offer }
  it { should have_one :primary_offer }
  it { should belong_to :partner }

  it { should validate_presence_of :name }

  before :each do
    require 'fake_aws'

    @partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    @survey_offer = Factory(:survey_offer)
  end

  it "should accept nested attributes for survey_questions" do
    @survey_offer.should respond_to(:survey_questions_attributes=)
  end

  it "should validate presence of bid_price on create" do
    survey_offer = SurveyOffer.new(:name => 'bob')
    survey_offer.save.should be_false
    survey_offer.errors.on(:bid_price).should == "can't be blank"
  end

  describe "callbacks" do
    it "should assign the Tapjoy partner id" do
      @survey_offer.partner_id.should == TAPJOY_PARTNER_ID
    end

    it "should create a primary_offer after create" do
      @survey_offer.primary_offer.should_not be_nil
      primary_offer = @survey_offer.primary_offer

      primary_offer.id.should               == @survey_offer.id
      primary_offer.item.should             == @survey_offer
      primary_offer.partner.id.should       == TAPJOY_PARTNER_ID
      primary_offer.name.should             == @survey_offer.name
      json = @survey_offer.to_json(:include => :survey_questions)
      primary_offer.reward_value.should     == 15
      primary_offer.price.should            == 0
      url_params = [
        "id=#{@survey_offer.id}",
        "udid=TAPJOY_UDID",
        "click_key=TAPJOY_SURVEY",
      ]
      url = "#{API_URL}/survey_results/new?#{url_params.join('&')}"
      primary_offer.url.should              == url
      primary_offer.bid.should              == 0
      primary_offer.device_types.should     == Offer::ALL_DEVICES.to_json
      primary_offer.tapjoy_enabled.should   == true
      primary_offer.user_enabled.should     == false
    end

    it "should create the offer icon" do
      fake_object = FakeObject.new('icons/checkbox.jpg')
      Offer.any_instance.expects(:save_icon!).with(fake_object.read)
      survey_offer = SurveyOffer.new(:name => 'bob', :bid_price => 0)
      survey_offer.save
    end

    it "should update the primary_offer after update" do
      partner = Factory(:partner)

      @survey_offer.update_attributes({
        :partner    => partner,
        :name       => 'bill',
        :hidden     => true,
        :bid        => 5,
      })

      @survey_offer.survey_questions << Factory(:survey_question)
      @survey_offer.reload

      primary_offer = @survey_offer.primary_offer
      primary_offer.partner.should == partner
      primary_offer.name.should == 'bill'
      primary_offer.hidden.should be_true
      primary_offer.bid.should == 5
      json = @survey_offer.to_json(:include => :survey_questions)

      @survey_offer = SurveyOffer.find(@survey_offer.id)
      @survey_offer.update_attributes({ :name => 'tom' })
      primary_offer.reload
      primary_offer.bid.should == 5
    end
  end

  it "should have a 'visible' scope" do
    SurveyOffer.visible.should == [@survey_offer]
    @survey_offer.hide!
    SurveyOffer.visible.should == []
  end

  it "should handle bid price" do
    survey_offer = SurveyOffer.new(:name => 'bob')
    survey_offer.bid.should == nil
    survey_offer.bid = 0
    survey_offer.bid.should == 0
    survey_offer.save

    survey_offer.primary_offer.bid.should == 0
    survey_offer.bid = 5
    survey_offer.bid.should == 5
    survey_offer.primary_offer.bid.should == 0
    survey_offer.save
    survey_offer.reload
    survey_offer.primary_offer.bid.should == 5

    survey_offer = SurveyOffer.find(survey_offer.id)
    survey_offer.bid.should == 5
  end

  it "should to_s to its name" do
    survey_offer = SurveyOffer.new(:name => 'billy')
    survey_offer.to_s.should == 'billy'
  end

  it "should delegate enabled? to primary_offer" do
    primary_offer = @survey_offer.primary_offer

    @survey_offer.enabled?.should == false
    primary_offer.is_enabled?.should == false

    @survey_offer.enabled = true
    primary_offer.reload
    primary_offer.is_enabled?.should == true
  end

  it "should build blank questions" do
    @survey_offer.survey_questions.size.should == 0
    @survey_offer.build_blank_questions
    @survey_offer.survey_questions.size.should == 4
    @survey_offer.build_blank_questions 8
    @survey_offer.survey_questions.size.should == 8
  end

  it "should remove blank questions" do
    question_1 = Factory(:survey_question, :survey_offer => @survey_offer)
    question_2 = Factory(:survey_question, :survey_offer => @survey_offer)

    @survey_offer.survey_questions.sort { |a,b| a.id <=> b.id }.should == [question_1, question_2].sort { |a,b| a.id <=> b.id }

    question_1_attrs = { 'text' => '', :id => question_1.id }
    question_2_attrs = { 'text' => 'yay', :id => question_2.id }
    questions_attrs = { 1 => question_1_attrs, 2 => question_2_attrs }

    @survey_offer.survey_questions_attributes=(questions_attrs)
    @survey_offer.save

    @survey_offer.reload
    @survey_offer.survey_questions.should == [question_2]

    @survey_offer.survey_questions_attributes=(nil)
    @survey_offer.survey_questions.should == [question_2]

    question_2.reload
    question_2.text.should == 'yay'
  end

  it "should have a 'visible' scope" do
    SurveyOffer.visible.should == [@survey_offer]
    @survey_offer.hide!
    SurveyOffer.visible.should == []
  end

  it "should handle bid price" do
    survey_offer = SurveyOffer.new(:name => 'bob')
    survey_offer.bid.should == nil
    survey_offer.bid = 0
    survey_offer.bid.should == 0
    survey_offer.save

    survey_offer.primary_offer.bid.should == 0
    survey_offer.bid = 5
    survey_offer.bid.should == 5
    survey_offer.primary_offer.bid.should == 0
    survey_offer.save
    survey_offer.reload
    survey_offer.primary_offer.bid.should == 5
  end

  it "should to_s to its name" do
    survey_offer = SurveyOffer.new(:name => 'billy')
    survey_offer.to_s.should == 'billy'
  end

  it "should delegate enabled? to primary_offer" do
    @survey_offer.enabled?.should == false
    @survey_offer.primary_offer.user_enabled = true
    @survey_offer.enabled?.should == true
  end

  it "should build blank questions" do
    @survey_offer.survey_questions.size.should == 0
    @survey_offer.build_blank_questions
    @survey_offer.survey_questions.size.should == 4
    @survey_offer.build_blank_questions 8
    @survey_offer.survey_questions.size.should == 8
  end

  it "should remove blank questions" do
    question_1 = Factory(:survey_question, :survey_offer => @survey_offer)
    question_2 = Factory(:survey_question, :survey_offer => @survey_offer)

    @survey_offer.survey_questions.sort { |a,b| a.id <=> b.id }.should == [question_1, question_2].sort { |a,b| a.id <=> b.id }

    question_1_attrs = { 'text' => '', :id => question_1.id }
    question_2_attrs = { 'text' => 'yay', :id => question_2.id }
    questions_attrs = { 1 => question_1_attrs, 2 => question_2_attrs }

    @survey_offer.survey_questions_attributes=(questions_attrs)
    @survey_offer.save

    @survey_offer.reload
    @survey_offer.survey_questions.should == [question_2]

    question_2.reload
    question_2.text.should == 'yay'
  end
end
