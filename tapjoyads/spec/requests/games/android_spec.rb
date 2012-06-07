require 'spec_helper'

describe "Android marketplace" do
  before :each do
    fake_the_web
  end

  let(:testapp) { Factory(:app) }
  let(:udid) { 'testudid' }

  describe "GET /games" do
    it "redirects to games/login" do

      # generate the verifier
      verifier_hash_bits = [ testapp.id, udid, nil, testapp.secret_key ]
      verifier = Digest::SHA256.hexdigest(verifier_hash_bits.join(':'))

      get "/games/android", { :verifier => verifier, :udid => udid, :app_id => testapp.id }

      response.body.should match("redirected")
      response.body.should match("http://www.example.com/games/login")
    end
  end
end
