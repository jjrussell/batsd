require 'spec_helper'

describe Linkshare do
  describe '.add_params' do
    context 'given iTunes url' do
      it 'adds linkshare info' do
        url = 'http://itunes.apple.com/us/app/tapdefense/id297558390?mt=8'
        new_url = Linkshare.add_params(url)
        new_url.should =~ /\?mt=8&\w+=\w+&\w+=\w+$/
      end

      context 'without ?' do
        it 'adds linkshare info and ?' do
          url = 'http://itunes.apple.com/us/app/tapdefense/id297558390'
          new_url = Linkshare.add_params(url)
          new_url.should =~ /\?\w+=\w+&\w+=\w+$/
        end
      end
    end

    context 'given non-iTunes url' do
      it 'returns the same url' do
        url = 'https://play.google.com/store/apps/details?id=com.tapjoy.tapjoy'
        Linkshare.add_params(url).should == url
      end
    end
  end
end
