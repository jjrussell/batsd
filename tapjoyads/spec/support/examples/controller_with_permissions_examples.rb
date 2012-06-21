shared_examples "a controller with permissions" do
  PERMISSIONS_MAP.each_pair do |action, map|
    describe "##{action}" do
      let(:params) { map[:params].present? ? map[:params] : {} }
      
      map[:permissions].each_pair do |user_type, permission|
        context "when logged in as #{user_type.to_s.humanize.downcase} user" do
          include_context "logged in as user type", user_type
          if permission
            it "allows access" do
              get action, params
              response.should be_success
            end
          else
            it "disallows access" do
              get action, params
              response.should_not be_success
            end
          end
        end
      end
    end
  end
end
