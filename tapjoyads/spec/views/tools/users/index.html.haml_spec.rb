require 'spec_helper'

describe 'dashboard/tools/users/index.html.haml' do

  context 'with a role manager user' do
    before :each do
      @user = Factory :role_mgr_user
      @tapjoy_users = [@user]
      render
    end

    it 'displays the link to edit a user' do
      rendered.should have_link(@user.id, :href => tools_user_path(@user))
    end

    it 'displays the roles assigned to that user' do
      rendered.should have_selector("li.role_mgr")
    end
  end
end
