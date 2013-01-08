require 'spec_helper'

describe RangedHash do
  describe 'getting & setting' do
    let(:now) { Time.zone.now }

    before :each do
      Timecop.freeze(now)
    end

    let(:ranged_hash) { RangedHash.new(now-10.minutes..now+10.minutes => 3.0) }

    it('returns 3.0 with a time in the range as key') { ranged_hash[now].should == 3.0 }
    it('returns nil for a key not in the range') { ranged_hash[now+20.minutes].should be_nil }
    it('returns 3.0 for the lower bound') { ranged_hash[now-10.minutes].should == 3.0 }
    it('returns 3.0 for the upper bound') { ranged_hash[now+10.minutes].should == 3.0 }

    after :each do
      Timecop.return
    end
  end
end
