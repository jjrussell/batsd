require 'spec_helper'

describe ShortUrl do
  subject { Factory(:short_url) }

  describe '#valid?' do
    it { should validate_uniqueness_of(:token) }
  end

  describe '.shorten' do
    before :each do
      @long_url = '/foo'
      @token = 'bar'
      @expiry = Time.zone.now + 30.days
    end
    context 'given a url' do
      it 'returns a ShortUrl Object with same long url' do
        s_url = ShortUrl.shorten(@long_url)
        s_url.is_a?(ShortUrl).should == true
        s_url.long_url.should == @long_url
      end
    end
    context 'given a token' do
      it 'returns a ShortUrl Object with same token' do
        s_url = ShortUrl.shorten(@long_url, nil, @token)
        s_url.is_a?(ShortUrl).should == true
        s_url.token.should == @token
      end
    end
    context 'given an expiration' do
      it 'returns a ShortUrl Object with proper expiration' do
        s_url = ShortUrl.shorten(@long_url, @expiry)
        s_url.is_a?(ShortUrl).should == true
        s_url.expiry.should == @expiry
      end
    end
  end
end
