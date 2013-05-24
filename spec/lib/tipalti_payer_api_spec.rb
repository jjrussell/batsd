require 'spec_helper'

describe TipaltiPayerApi do
  before :each do
    @tipalti = TipaltiPayerApi.new
  end

  describe '#get_dynamic_key' do
    around :each do |example|
      VCR.use_cassette('tipalti_payer/get_dynamic_key') do
        example.run
      end
    end

    # This should always be the case (and is set by Tipalti)
    context 'when enhanced security is enabled in our Tipalti account' do
      before :each do
        @response = @tipalti.get_dynamic_key(Time.now)
      end

      it 'has an error_code of "OK"' do
        @response[:error_code].should == 'OK'
      end

      it 'returns a 16-character token string' do
        @response[:token].should have(16).characters
      end

      it 'returns a 64-character key string' do
        @response[:key].should have(64).characters
      end
    end
  end
end

