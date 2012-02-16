require 'spec_helper'

describe ToolsHelper do
  describe 'device info click_tr_class' do
    before :each do
      @reward = mock()
      @reward.stubs(:successful?).returns(true)
      @click = mock()
      @click.stubs(:installed_at?).returns(true)
      @click.stubs(:type).returns('install')
      @click.stubs(:key).returns(Factory.next(:guid))
      @click.stubs(:block_reason?).returns(false)
      @click.stubs(:block_reason).returns(nil)
    end

    it 'checks rewarded click' do
      @helper.click_tr_class(@click, @reward).should == 'rewarded'
      @helper.click_tr_class(@click, nil).should == 'rewarded-failed'
      @click.stubs(:installed_at?).returns(false)
      @helper.click_tr_class(@click, nil).should == ''
    end

    it 'checks jailbroken' do
      @click.stubs(:type).returns('install_jailbroken')
      @helper.click_tr_class(@click, @reward).should == 'rewarded jailbroken'
    end

    it 'checks param click key' do
      params[:click_key] = @click.key
      @helper.click_tr_class(@click, @reward).should == 'rewarded click-key-match'
    end

    it 'checks block_reason' do
      @click.stubs(:installed_at?).returns(false)
      @click.stubs(:block_reason?).returns(true)
      @click.stubs(:block_reason).returns('Banned')
      @helper.click_tr_class(@click, nil).should == 'blocked'
      @click.stubs(:block_reason).returns('TooManyUdidsForPublisherUserId')
      @helper.click_tr_class(@click, nil).should == 'blocked'
      @click.stubs(:block_reason).returns('SomeOtherReason')
      @helper.click_tr_class(@click, nil).should == 'not-rewarded'
    end
  end
end
