require 'spec_helper'

describe Countries do
  describe '.continent_code_to_country_codes' do
    before :each do
      @countries = Countries.continent_code_to_country_codes
    end

    it 'does not include North Korea' do
      @countries.values.flatten.should_not include('KP')
    end

    it 'does not include Metropolitan France' do
      @countries.values.flatten.should_not include('FX')
    end

    it 'lists Cyprus under Europe' do
      @countries['EU'].should include('CY')
    end
  end
end
