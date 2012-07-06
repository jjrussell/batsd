require 'spec_helper'

describe FavoriteApp do
  describe '.belongs_to' do
    it { should belong_to :gamer }
    it { should belong_to :app_metadata }
  end
end
