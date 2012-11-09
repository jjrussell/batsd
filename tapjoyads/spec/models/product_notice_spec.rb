require 'spec_helper'

describe ProductNotice do
  it 'uses "tapjoy.product_notice" for a Redis key' do
    described_class.key.should == 'dashboard.product_notice'
  end

  describe '#message' do
    it 'has a message' do
      described_class.should respond_to :message
    end

    it 'is blank by default' do
      described_class.message.should be_blank
    end
  end

  describe '#message=' do
    let(:sample_message) { "Some awesome message." }
    it 'sets the message in Redis' do
      $redis.should_receive(:set).with(described_class.key, sample_message)
      described_class.message = sample_message
    end

    it 'changes the message' do
      described_class.message = "Some previous message"
      expect{described_class.message = sample_message}.to change{described_class.message}
    end
  end

  describe '#empty?' do
    it 'is true if the message is empty' do
      described_class.stub(:message).and_return('')
      described_class.should be_empty
    end
  end

end
