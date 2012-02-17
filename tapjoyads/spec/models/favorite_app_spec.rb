require 'spec_helper'

describe VideoOffer do
  before :each do
    fake_the_web
  end

  context 'when associating' do
    it 'belongs to' do
      should belong_to :gamer
      should belong_to :app
    end
  end
end
