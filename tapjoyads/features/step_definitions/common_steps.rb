Given /^I have an app$/ do
  @app = FactoryGirl.create :app, :partner => @partner
  @offer = @app.primary_offer
end

When /^I visit the "(.*?)" page$/ do |page|
  visit path_for(page)
end
