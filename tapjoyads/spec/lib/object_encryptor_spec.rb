require 'spec_helper'

describe ObjectEncryptor do
  describe '.encrypt_url' do
    context 'when given a url' do
      it 'encrypts the parameters for that url' do
        expected_hash = {
          'date' => '02/24/2012',
          'end_date' => '02/28/2012',
          'granularity' => 'hourly'
        }
        old_url = "https://dashboard.tapjoy.com/statz/c5d77993-0294-41ec-9830-c1b70c1a981d?#{expected_hash.to_params}"

        new_url = ObjectEncryptor.encrypt_url(old_url)
        params = CGI.parse(URI.parse(new_url).query)
        params.keys.should == [ 'data' ]
        actual_hash = ObjectEncryptor.decrypt(params['data'].first)
        actual_hash.should == expected_hash
      end
    end
  end
end
