require 'spec_helper'

describe RiskActionSet do
  subject { RiskActionSet.new }

  describe '#add' do
    context 'when adding action that is not supported' do
      it "doesn't add the action" do
        subject.add("NOT_SUPPORTED").actions.should be_empty
      end
    end

    context 'when adding supported action' do
      context 'that is already present' do
        before :each do
          @actions = subject.add("DELAY48").actions
        end

        it 'does nothing' do
          subject.actions.should == @actions
          subject.add("DELAY48").actions.should == @actions
        end
      end

      context 'that is not superseded' do
        it 'adds the action' do
          subject.add("DELAY48").actions.include?("DELAY48").should be_true
        end

        context 'and supersedes other actions' do
          it 'removes the superseded actions' do
            subject.add("DELAY24").actions.include?("DELAY24").should be_true
            subject.add("DELAY48").actions.include?("DELAY24").should be_false
          end
        end
      end

      context 'that is superseded' do
        before :each do
          @actions = subject.add("DELAY48").actions
        end

        it 'does nothing' do
          subject.actions.should == @actions
          subject.add("DELAY24").actions.should == @actions
        end
      end
    end
  end

  describe '#merge' do
    context 'when merging array of actions' do
      it 'adds each action in array' do
        @actions = subject.merge(["FLAG", "BAN"]).actions
        @actions.include?("FLAG").should be_true
        @actions.include?("BAN").should be_true
      end
    end
  end
end
