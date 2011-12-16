require 'spec_helper'

describe Recommender do
  before do
    @interface_methods = %w(most_popular for_app for_device).map(&:to_sym)
    @recommenders = Recommender::ACTIVE_RECOMMENDERS.keys.map { |x| "Recommenders::#{x.to_s.camelize}".constantize.instance }
  end

  it "recommenders should respond to all the basic interface commands" do
    @recommenders.each { |r| @interface_methods.each { |m| r.should respond_to m } }
  end

  it "should return recommendations for app in the correct data structure" do
    app = "9f47822c-2183-4969-98b1-ce64430e4e58"
    udid = "statz_test_udid"
    @recommenders.each do |r|
      r.cache_all
      r.for_app(app).should be_an Array
      r.for_app(app, :n => 15).should have_at_most(15).items
      r.for_app(app).first.should be_a Array
      r.for_app(app).first.first.should be_a String
      r.for_app(app).first.last.should be_a Numeric
      r.for_device(udid).should be_an Array
      r.for_device(udid, :n => 15).should have_at_most(15).items
      r.for_device(udid).first.should be_a Array
      r.for_device(udid).first.first.should be_a String
      r.for_device(udid).first.last.should be_a Numeric
      r.most_popular.should be_an Array
      r.most_popular(:n => 15).should have_at_most(15).items
      r.most_popular.first.should be_a Array
      r.most_popular.first.first.should be_a String
      r.most_popular.first.last.should be_a Numeric
    end
  end
end
