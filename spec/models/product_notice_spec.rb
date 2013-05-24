require 'spec_helper'

describe ProductNotice do
  let(:sample_message)         { "Some awesome message." }
  let(:another_sample_message) { "Some other message." }

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

  describe '#to_s' do
    it 'is aliased to #message' do
      subject.message = sample_message
      subject.to_s.should == subject.message
    end
  end

  describe '#message=' do
    it 'sets the message in Redis' do
      $redis.should_receive(:set).with(described_class.key, sample_message)
      subject.message = sample_message
    end

    it 'changes the message' do
      subject.message = another_sample_message
      expect{subject.message = sample_message}.to change{subject.message}
    end
  end

  describe '#empty?' do
    it 'is true if the message is empty' do
      subject.stub(:message).and_return('')
      subject.should be_empty
    end
  end

  describe '#force_update!' do
    it 're-reads from Redis' do
      $redis.should_receive(:get)
      subject.force_update!
    end

    it 'changes the message if the Redis string has been updated' do
      subject.message = sample_message
      $redis.set(described_class.key, another_sample_message)
      expect{subject.force_update!}.to change{subject.message}
    end
  end

  describe '.most_recent' do
    it "is a #{described_class}" do
      described_class.most_recent.should be_a described_class
    end

    it 'uses the most recent message' do
      $redis.set(described_class.key, sample_message)
      described_class.most_recent.message.should == sample_message
    end
  end
end
