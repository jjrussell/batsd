require 'spec_helper'

describe Games::SupportController do
  before :each do
    activate_authlogic

    gamer = Factory(:gamer)
    gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => gamer)
    login_as(gamer)
  end

  describe '#create' do
    context 'without supplying a message' do
      it "fails validation if no message is provided"

      it "redirects to back to #new if no message is provided"
    end

    context 'with a message' do
      context 'with a click selected' do

      end

      context 'without a click selected' do

      end

      it 'creates a SupportRequest'
    end
  end

  describe '#new' do
    context 'when format is set to JS' do
      it 'gathers the correct values for @unresolved_clicks'
    end
  end
end
