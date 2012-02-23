require 'spec_helper'

describe FavoriteApp do
  before :each do
    fake_the_web
  end

  describe '.belongs_to' do
    it { should belong_to :gamer }
    it { should belong_to :app_metadata }
  end
end
