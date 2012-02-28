require 'spec_helper'

describe ObjectEncryptor do
  describe '.encrypt_url' do
    context 'when given a url' do
      it 'encrypts the parameters for that url' do
        old_url = 'https://dashboard.tapjoy.com/statz/c5d77993-0294-41ec-9830-c1b70c1a981d?date=02/24/2012&end_date=02/28/2012&granularity=hourly'
        new_url = 'https://dashboard.tapjoy.com/statz/c5d77993-0294-41ec-9830-c1b70c1a981d?data=f650b082a61bf992d08a694553f8874319d7495756c55515f5e77dad422ea4c61cc40d461cff2824f7da5e3302792a2f91a1a5ac0c9d6cb731c32f2d0a1fde4dc67b0be7c4d3c31284d41d030ebc1bd0'
        ObjectEncryptor.encrypt_url(old_url).should == new_url
      end
    end
  end
end
