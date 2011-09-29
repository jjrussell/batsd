require 'spec_helper'

describe "an instance generated by a factory" do
  before do
    define_model("User")

    FactoryGirl.define do
      factory :user
    end
  end

  it "registers the user factory" do
    FactoryGirl.factory_by_name(:user).should be_a(FactoryGirl::Factory)
  end
end
