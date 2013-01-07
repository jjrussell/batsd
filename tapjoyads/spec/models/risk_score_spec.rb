require 'spec_helper'

describe RiskScore do
  subject { RiskScore.new }

  before :each do
    RiskProfile.any_instance.stub(:save)
    @individual_profile = RiskProfile.new(:key => 'DEVICE.1234567890')
    @individual_profile.add_curated_offset('test1', 35)
    @individual_profile.add_historical_offset('test2', -20)
    @system_profile = RiskProfile.new(:key => 'OFFER.1234567890')
    @system_profile.add_curated_offset('test3', 5)
    @system_profile.add_historical_offset('test4', 30)
    @rule = RiskRule.new('rule1', 90, Proc.new {true}, ['BAN', 'BLOCK'])
  end

  describe '#add_offset' do
    it 'adds offset' do
      subject.add_offset(@individual_profile)
      attempt = ConversionAttempt.new
      attempt.should_receive(:add_risk_profile).with(@individual_profile).once
      subject.record_details(attempt)
    end
  end

  describe '#rule_matched' do
    it 'adds matched rule' do
      subject.rule_matched(@rule)
      attempt = ConversionAttempt.new
      subject.record_details(attempt)
      attempt.rules_matched.keys.should == ['rule1']
    end
  end

  describe '#final_score' do
    it 'returns final score' do
      subject.add_offset(@individual_profile)
      subject.add_offset(@system_profile)
      subject.rule_matched(@rule)
      subject.final_score.should == RiskScore::STARTING_SCORE + 126.0
    end
  end

  describe '#record_details' do
    context 'when no offsets and rules are added' do
      it 'returns ConversionAttempt with none' do
        attempt = ConversionAttempt.new
        subject.record_details(attempt)
        attempt.risk_profiles.should == {}
        attempt.rules_matched.should == {}
        attempt.system_entities_offset.to_f.should == 0.0
        attempt.individual_entities_offset.to_f.should == 0.0
        attempt.rules_offset.to_f.should == 0.0
        attempt.final_risk_score.to_f.should == RiskScore::STARTING_SCORE
      end
    end

    it 'writes score details to ConversionAttempt' do
      subject.add_offset(@individual_profile)
      subject.add_offset(@system_profile)
      subject.rule_matched(@rule)
      attempt = ConversionAttempt.new
      subject.record_details(attempt)
      attempt.risk_profiles.keys.include?(@individual_profile.key).should be_true
      attempt.risk_profiles.keys.include?(@system_profile.key).should be_true
      attempt.rules_matched.keys.should == ['rule1']
      attempt.system_entities_offset.to_f.should == 17.0 * RiskScore::CATEGORY_OFFSET_LIMIT / RiskProfile::OFFSET_MAXIMUM
      attempt.individual_entities_offset.to_f.should == 7.0 * RiskScore::CATEGORY_OFFSET_LIMIT / RiskProfile::OFFSET_MAXIMUM
      attempt.rules_offset.to_f.should == 90.0
      attempt.final_risk_score.to_f.should == RiskScore::STARTING_SCORE + 126.0
    end
  end
end
