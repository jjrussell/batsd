require 'spec_helper'

describe Recommender do
  before do
    @interface_methods = %w(most_popular_apps recommendations_for_app recommendations_for_udid).map(&:to_sym)
    @recommenders = Recommender::ACTIVE_RECOMMENDERS.keys.map { |x| "Recommenders::#{x.to_s.camelize}".constantize.instance }
  end

  it "recommenders should respond to all the basic interface commands" do
    @recommenders.each { |r| @interface_methods.each { |m| r.should respond_to m } }
  end

  it "should return recommendations for app in the correct data structure" do
    app = Recommender.instance(:app_affinity_recommender).random_app
    @recommenders.each do |r|
      r.recommendations_for_app(app).should be_an Array
      r.recommendations_for_app(app, :n => 15).should have_at_most(15).items
      r.recommendations_for_app(app).first.should be_a Hash
      r.recommendations_for_app(app).first[:app_id].should be_a String
      r.recommendations_for_app(app).first[:weight].should be_a Numeric
    end
  end

  it "should return recommendations for udid in the correct data structure" do
    udid = Recommender.instance(:app_affinity_recommender).random_udid
    @recommenders.each do |r|
      r.recommendations_for_udid(udid).should be_an Array
      r.recommendations_for_udid(udid, :n => 15).should have_at_most(15).items
      r.recommendations_for_udid(udid).first.should be_a Hash
      r.recommendations_for_udid(udid).first[:app_id].should be_a String
      r.recommendations_for_udid(udid).first[:weight].should be_a Numeric
    end
  end

  it "should return the most popular apps with the correct options" do
    @recommenders.each do |r|
      r.most_popular_apps.should be_an Array
      r.most_popular_apps(:n => 15).should have_at_most(15).items
      r.most_popular_apps.first.should be_a Hash
      r.most_popular_apps.first[:app_id].should be_a String
      r.most_popular_apps.first[:weight].should be_a Numeric
    end
  end
end
