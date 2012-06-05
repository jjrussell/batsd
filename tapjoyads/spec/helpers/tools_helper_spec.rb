require 'spec_helper'

describe ToolsHelper do
  describe '#click_tr_class' do
    before :each do
      @reward = mock()
      @reward.stub(:successful?).and_return(true)
      @click = mock()
      @click.stub(:installed_at?).and_return(true)
      @click.stub(:type).and_return('install')
      @click.stub(:key).and_return(Factory.next(:guid))
      @click.stub(:block_reason?).and_return(false)
      @click.stub(:block_reason).and_return(nil)
    end

    it 'checks rewarded click' do
      helper.click_tr_class(@click, @reward).should == 'rewarded'
      helper.click_tr_class(@click, nil).should == 'rewarded-failed'
      @click.stub(:installed_at?).and_return(false)
      helper.click_tr_class(@click, nil).should == ''
    end

    it 'checks jailbroken' do
      @click.stub(:type).and_return('install_jailbroken')
      helper.click_tr_class(@click, @reward).should == 'rewarded jailbroken'
    end

    it 'checks param click key' do
      helper.stub(:params).and_return({:click_key => @click.key})
      helper.click_tr_class(@click, @reward).should == 'rewarded click-key-match'
    end

    it 'checks block_reason' do
      @click.stub(:installed_at?).and_return(false)
      @click.stub(:block_reason?).and_return(true)
      @click.stub(:block_reason).and_return('Banned')
      helper.click_tr_class(@click, nil).should == 'blocked'
      @click.stub(:block_reason).and_return('TooManyUdidsForPublisherUserId')
      helper.click_tr_class(@click, nil).should == 'blocked'
      @click.stub(:block_reason).and_return('SomeOtherReason')
      helper.click_tr_class(@click, nil).should == 'not-rewarded'
    end
  end

  describe '#install_td_class' do
    before :each do
      @click = mock()
      @click.stub(:block_reason?).and_return(false)
      @click.stub(:resolved_too_fast?).and_return(false)
    end

    it 'assigns class small' do
      helper.install_td_class(@click).should match(/\bsmall\b/)
    end

    context 'blocked_click' do
      before :each do
        @click.stub(:block_reason?).and_return(true)
      end

      it 'assigns class bad' do
        helper.install_td_class(@click).should match(/\bbad\b/)
      end
    end

    context 'resolved too fast' do
      before :each do
        @click.stub(:resolved_too_fast?).and_return(true)
      end

      it 'assigns class bad' do
        helper.install_td_class(@click).should match(/\bbad\b/)
      end
    end
  end

  describe '#concat_li_currency' do
    before :each do
      helper.output_buffer = ''
    end

    it 'defaults to 0 when amount is set to nil' do
      helper.send(:concat_li_currency, 'Name', nil)
      helper.output_buffer.should match(/\$0\.00/)
    end
  end
end
