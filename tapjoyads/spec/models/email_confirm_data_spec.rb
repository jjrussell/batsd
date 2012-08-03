# encoding: UTF-8

require 'spec_helper'

describe EmailConfirmData do
  subject { EmailConfirmData.new }
  describe '#to_hash' do
    it 'returns array of atttibutes with correct' do
      subject.content             = 'test'
      subject.user_agent_str      = 'uas'
      subject.accept_language_str = 'alr'
      subject.selected_devices    = 'ipod,android'
      subject.id                  = 'a_really_unique_id'
      subject.geoip_data          = { :carrier_country_code => 'US', :primary_country => 'CA', :user_country_code => 'JP' }

      subject.to_hash.should == {
        :content             => 'test',
        :user_agent_str   => 'uas',
        :accept_language_str => 'alr',
        :selected_devices    => 'ipod,android',
        :id                  => 'a_really_unique_id',
        :geoip_data          => { :carrier_country_code => 'US', :primary_country => 'CA', :user_country_code => 'JP' } }
    end
  end

  describe '#expire' do
    it 'should call expire on redis adapter' do
      subject.adapter.client.should_receive(:expire)
      subject.expire()
    end
  end
end
