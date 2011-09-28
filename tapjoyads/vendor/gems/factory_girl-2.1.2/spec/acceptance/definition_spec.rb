require 'spec_helper'

describe "an instance generated by a factory with a custom class name" do
  before do
    define_model("User", :admin => :boolean)

    FactoryGirl.define do
      factory :user

      factory :admin, :class => User do
        admin { true }
      end
    end
  end

  subject { FactoryGirl.create(:admin) }

  it "uses the correct class name" do
    should be_kind_of(User)
  end

  it "uses the correct factory definition" do
    should be_admin
  end
end

