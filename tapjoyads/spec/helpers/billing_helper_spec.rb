require 'spec_helper'

describe BillingHelper do
  describe '#list_of_countries' do
    it 'has the United States' do
      helper.list_of_countries.should include "United States of America"
    end
  end

  describe '#list_of_states' do
    it 'should have California' do
      helper.list_of_states.should include ["California", "CA"]
    end
  end
end
