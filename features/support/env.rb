ENV['CUCUMBER'] = 'true'

require 'cucumber/rails'
require 'factory_girl'

Capybara.default_selector = :css
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# Allow step definitions to wait until jQuery is no longer 'active' (eg. has open XHR sockets)
def wait_for_ajax(timeout = Capybara.default_wait_time)
  page.wait_until(timeout) do
    page.evaluate_script 'jQuery.active == 0'
  end
end

# Fix for an error with the onchange event handler in Capybara:
# https://groups.google.com/forum/?fromgroups#!topic/ruby-capybara/LZ6eu0kuRY0
class Capybara::Selenium::Node < Capybara::Driver::Node
  def set(value)
    if tag_name == 'textarea' or (tag_name == 'input' and %w(text password hidden file).include?(type))
      keys = ""
      # delete existing values from field.. does not use node.clear as this trigger onchange event..
      keys << "\b" * native[:value].size if native[:value]
      keys << value.to_s

      native.send_keys(keys)
      # execute onchange script after update is finished if it exists..
      native.bridge.executeScript("$('#{native[:id]}').onchange()") if native[:onchange]
    elsif tag_name == 'input' and type == 'radio'
      native.click
    elsif tag_name == 'input' and type == 'checkbox'
      native.click if native.attribute('checked') != value
    end
  end
end

Before do
  Seeder.run!
end

Before('@tapjoy_marketer') do
  @partner ||= FactoryGirl.create(:partner, :id => TAPJOY_SURVEY_PARTNER_ID, :balance => 10_000)
  @user    ||= FactoryGirl.create(:user, :with_admin_role, :current_partner => @partner)
  login!
end

Before('@partner') do
  @partner ||= FactoryGirl.create(:partner)
  @user    ||= FactoryGirl.create(:user, :current_partner => @partner)
  login!
end

Before('@account_manager') do
  @partner ||= FactoryGirl.create(:partner)
  @user    ||= FactoryGirl.create(:user, :with_account_mgr_role, :current_partner => @partner)
  login!
end

Before('@stub_resolvable_host') do
  Resolv.send(:define_method, :getaddress) { true }
end

def login!
  visit '/login'
  fill_in 'Email Address', :with => @user.email
  fill_in 'Password', :with => DEFAULT_FACTORY_PASSWORD
  click_button 'Log in'
end

def retry_on_timeout(n = 3, &block)
  block.call
rescue Capybara::TimeoutError, Capybara::ElementNotFound => e
  raise e if n <= 0
  puts "Caught #{e.class.name} error: #{e.message}. #{n-1} more attempts."
  retry_on_timeout(n - 1, &block)
end

Cucumber::Rails::Database.javascript_strategy = :truncation
