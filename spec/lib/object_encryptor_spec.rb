require 'spec_helper'

describe ObjectEncryptor do
  describe '.encrypt_url' do
    context 'when given a url' do
      let(:expected_hash) { {
          'date' => '02/24/2012',
          'end_date' => '02/28/2012',
          'granularity' => 'hourly',
          'publisher_app' => 'some app stuff',
          'publisher_user_id' => '5d7aa993-0a294a-41becb-98b30-cbdsf1b70c1a981d',
          'udid' => '3424334243243434343432432432',
          'currency_id' => '5d77993-0294-41ec-9830-c1b70c1a981d',
          'source' => ' http : // tjvideo.tjvideo.com/tjvidel ',
          'app_version' => ' params[:library_version], rl ',
          'viewed_at' => ' e ',
          'exp' => ' whatever ',
          'primary_country' => ' USA ',
          'language_code' => ' zh-cn ',
          'display_multiplier' => ' 2.5000 ',
          'device_name' => ' iphone 5040 '
      } }

      let(:old_url) { "https://dashboard.tapjoy.com/statz/c5d77993-0294-41ec-9830-c1b70c1a981d?#{expected_hash.to_params}" }

      it 'encrypts the parameters for that url' do
        new_url = ObjectEncryptor.encrypt_url(old_url)
        params = CGI.parse(URI.parse(new_url).query)
        params.keys.should == ['data']
        actual_hash = ObjectEncryptor.decrypt(params['data'].first)
        actual_hash.should == expected_hash
      end

      it 'also works in base64 mode' do
        new_url = ObjectEncryptor.b64_encrypt_url(old_url)
        params = CGI.parse(URI.parse(new_url).query)
        params.keys.should == ['data']
        actual_hash = ObjectEncryptor.decrypt(params['data'].first)
        actual_hash.should == expected_hash
      end
    end
  end
end
