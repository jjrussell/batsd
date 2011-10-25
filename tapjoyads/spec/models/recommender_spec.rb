require 'spec_helper'

#Define the basic interface that all recommenders should adhere to in this test
describe Recommender do
  before do
    @interface_methods = %w(most_popular_apps recommendations_for_app recommendations_for_udid).map(&:to_sym)
    @recommenders = Recommender::ACTIVE_RECOMMENDERS.keys.map{|x| "Recommenders::#{x.to_s.camelize}".constantize.instance}
  end
  
  
  it "recommenders should respond to all the basic interface commands" do
    @recommenders.each{|r| @interface_methods.each{|m| r.should respond_to m}}
  end
  
  it "should return recommendations for app in the correct data structure" do
    app = @recommenders.first.most_popular_apps.last
    @recommenders.each do |r| 
      r.recommendations_for_app(app).should be_an Array
      r.recommendations_for_app(app).first.should be_a String
      r.recommendations_for_app(app, :with_weights => true).first.should be_an Array
      r.recommendations_for_app(app, :with_weights => true).first.first.should be_a String
      r.recommendations_for_app(app, :with_weights => true).first.last.should be_a Numeric
    end
  end

  it "should return the most popular apps with the correct options" do
    @recommenders.each do |r|
      r.most_popular_apps.should be_an Array
      r.most_popular_apps(:n => 15).should have(15).items
      r.most_popular_apps.first.should be_a String
      r.most_popular_apps(:with_weights => true).first.should be_an Array
      r.most_popular_apps(:with_weights => true).first.should have(2).items
      r.most_popular_apps(:with_weights => true).first.first.should be_a String
      r.most_popular_apps(:with_weights => true).first.last.should be_a Numeric
    end
  end
  
  
end
