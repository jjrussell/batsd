shared_examples "a controller with permissions" do
  PERMISSIONS_MAP.each_pair do |action, map|
    describe "##{action}" do
      let(:params) { map[:params].present? ? map[:params] : {} }
      
      map[:permissions].each_pair do |user_type, permission|
        context_name = "logged in as #{user_type.to_s.humanize.downcase}"
        
        context "when #{context_name}" do
          include_context context_name
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
