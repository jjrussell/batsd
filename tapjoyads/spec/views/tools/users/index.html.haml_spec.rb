require 'spec/spec_helper'

describe 'tools/users/index.html.haml' do

  context 'with a role manager user' do
    before :each do
      @user = Factory :role_mgr_user
      assigns[:tapjoy_users] = [@user]
      render
    end

    it 'displays the link to edit a user' do
      response.should have_tag("a[href=?]", tools_user_path(@user))
    end

    it 'displays the roles assigned to that user' do
      response.should have_tag("li.role_mgr")
    end
  end
end
