require 'spec_helper'

describe ServerWhitelist do
  describe ".ip_whitelist_includes?" do
    before :each do
      ServerWhitelist.stub(:get_whitelist_ips).and_return(['1.2.3.4', ['4.3.2.1', '4.3.2.111'], '8.9.10.11'])
    end

    context 'with whitelisted IP range' do
      context 'and IP in range' do
        it 'returns true' do
          ServerWhitelist.ip_whitelist_includes?('4.3.2.1').should be_true
        end

        it 'returns true' do
          ServerWhitelist.ip_whitelist_includes?('4.3.2.11').should be_true
        end

        it 'returns true' do
          ServerWhitelist.ip_whitelist_includes?('4.3.2.111').should be_true
        end
      end

      context 'and IP not in range' do
        it 'returns false' do
          ServerWhitelist.ip_whitelist_includes?('4.3.2.112').should be_false
        end
      end
    end

    context 'with whitelisted individual IP' do
      context 'and matching IP' do
        it 'returns true' do
          ServerWhitelist.ip_whitelist_includes?('8.9.10.11').should be_true
        end
      end

      context 'and non matching IP' do
        it 'returns false' do
          ServerWhitelist.ip_whitelist_includes?('127.0.0.1').should be_false
        end
      end
    end
  end
end
