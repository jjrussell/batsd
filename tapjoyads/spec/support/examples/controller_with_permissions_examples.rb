shared_examples "a controller with permissions" do
  PERMISSIONS_MAP.each_pair do |action, map|
    let(:params) { hash = map[:params].present? ? map[:params] : {}
                   Hash[hash.map do |k,v|
                     v = v.call if v.is_a?(Proc)
                     [k,v]
                   end] }
    
    map[:permissions].each_pair do |user_type, permission|
      context "when logged in as #{user_type.to_s.humanize.downcase} user, ##{action}" do
        include_context "logged in as user type", user_type
        if permission
          it "allows access" do
            controller.should be_permitted_to action
          end
        else
          it "disallows access" do
            controller.should_not be_permitted_to action
          end
        end
      end
    end
  end
end
