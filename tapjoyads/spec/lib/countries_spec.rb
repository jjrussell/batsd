require 'spec_helper'

describe Earth::Continent do
  describe '.continent_code_to_country_codes' do
    let(:continents) { described_class.continent_code_to_country_codes }

    it 'does not include North Korea' do
      continents.values.flatten.should_not include('KP')
    end

    it 'does not include Metropolitan France' do
      continents.values.flatten.should_not include('FX')
    end

    it 'lists Cyprus under Europe' do
      continents['EU'].should include('CY')
    end
  end
end
