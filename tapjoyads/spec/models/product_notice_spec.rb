require 'spec_helper'

describe ProductNotice do
  subject { described_class.instance }

  it 'is a Singleton' do
    described_class.should respond_to :instance
  end

  it 'uses "tapjoy.product_notice" for a Redis key' do
    described_class.key.should == 'dashboard.product_notice'
  end

  describe '#message' do
    it 'has a message' do
      subject.should respond_to :message
    end

    it 'is blank by default' do
      subject.message.should be_blank
    end
  end

  describe '#message=' do
    let(:sample_message) { "Some awesome message." }
    it 'sets the message in Redis' do
      $redis.should_receive(:set).with(described_class.key, sample_message)
      subject.message = sample_message
    end

    it 'changes the message' do
      subject.instance_variable_set(:@message, "Some previous message.")
      $redis.stub(:set).with(described_class.key, sample_message).and_return(sample_message)
      expect{subject.message = sample_message}.to change{subject.message}
    end
  end

  describe '#empty?' do
    it 'is true if the message is empty' do
      subject.stub(:message).and_return('')
      subject.should be_empty
    end
  end

end
