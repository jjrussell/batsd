##
##  These shared examples will check the controller-level permissions for all
##  publicy accessible actions on the current controller.  A spec will be performed
##  for all user role types (based on what roles are defined in authorization_rules.rb).
##
##  To define which user roles should have access to an action,
##
##    it_behaves_like "a controller with permissions", {
##       :index  => { :allowed => [ :account_mgr, :admin, :customer_service ]},
##       :show   => { :allowed => [ :account_mgr, :admin, :customer_service ]},
##    }
##
##  If the permissions hash is not defined, it is assumed that all actions should be
##  inaccessible to all user types. If the contoller being tested defines publicly
##  accessible actions that aren't included in the hash, it will be assumed that none
##  of the user roles should have access to that action.
##
##  Underlying Assumption: If you inadvertently open an action to a user role, this test
##  suite should fail, thereby alerting you to the potential security issue.

shared_examples "a controller with permissions" do |permissions_map|
  permissions_map ||= {}
  public_actions = described_class.public_instance_methods(false).reject { |method_name| method_name.to_s.first == '_' }.map(&:to_sym)
  available_roles = Authorization::Engine.instance.roles

  context "and" do   # This context just makes the rspec comments read better
    # Check actions in the permissions_map to make sure they're publicly accessible methods in the controller
    permissions_map.each_pair do |action, map|
      it "has a publicly accessible ##{action} action" do
        public_actions.should include(action)
      end

      # Check for roles in permissions_map that aren't in the declarative_authorization roles
      map[:allowed].each do |role|
        it "requires a #{role} user role" do
          available_roles.should include(role)
        end
      end
    end

    # Test accessibility on all public actions for all defined roles
    public_actions.each do |action|
      available_roles.each do |role|
        context "a user with the #{role} role" do

          # Log in as a user with the role to be tested
          include_context "logged in as user with role", role

          if defined?(permissions_map[action][:allowed]) && permissions_map[action][:allowed].include?(role)
            it "can access ##{action}" do
              controller.should be_permitted_to action
            end
          else
            it "cannot access ##{action}" do
              controller.should_not be_permitted_to action
            end
          end
        end
      end
    end
  end
end
