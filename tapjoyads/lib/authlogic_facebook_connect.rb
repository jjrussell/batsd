require "authlogic_facebook_connect/session"

if ActiveRecord::Base.respond_to?(:add_acts_as_authentic_module)
  Authlogic::Session::Base.send(:include, AuthlogicFacebookConnect::Session)
end
