require 'spec_helper'

describe Dashboard::ToolsController do
  include ActionView::Helpers
  render_views
  
  let(:device1)   { FactoryGirl.create(:device) }
  let(:device2)   { FactoryGirl.create(:device) }
  let!(:pub_user) { pub_user = FactoryGirl.create(:publisher_user)
                    pub_user.update!(device1.key)
                    pub_user.update!(device2.key)
                    pub_user }
  
  before :each do  
    PublisherUser.stub(:new).and_return(pub_user)
  end

  describe '#index' do
    context 'with a non-logged in user' do
      it 'redirects to login page' do
        get :index
        response.should redirect_to(login_path(:goto => tools_path))
      end
    end
    
    context 'with an unauthorized user' do
      include_context 'logged in as an agency user'
    
      context 'accessing tools index' do
        it 'redirects to dashboard' do
          get :index
          response.should redirect_to root_path
        end
      end
    end

    context 'with an admin user' do
      include_context 'logged in as an admin user'

      context 'accessing tools index' do
        it 'renders appropriate page' do
          get :index
          response.should render_template 'tools/index'
        end
      end
    end
  end

  describe '#partner_monthly_balance' do
    context 'with an admin user' do
      include_context 'logged in as an admin user'
    
      it 'gets correct months_list' do
        get :partner_monthly_balance
        months = assigns :months
        months.first.should == Date.parse('2009-06-01').strftime('%b %Y') #the first month of the platform
        months.last.should == Date.current.beginning_of_month.prev_month.strftime('%b %Y')
      end
    end
  end

  describe '#view_pub_user_account' do
    context 'when logged in as a customer service manager' do
      include_context 'logged in as a customer service manager'
      
      it 'succeeds' do
        app_id, user_id = pub_user.key.split('.')
        get(:view_pub_user_account, {:publisher_app_id => app_id, :publisher_user_id => user_id})
        (assigns(:devices).map {|d| d.key} - [device1, device2].map {|d| d.key}).should be_empty
        response.should render_template 'tools/view_pub_user_account'
      end
    end
  end
  
  describe '#detach_pub_user_account' do
    context 'when logged in as a customer service manager' do
      include_context 'logged in as a customer service manager'
      
      context 'with an invalid udid' do
        it 'does nothing' do
          app_id, user_id = pub_user.key.split('.')
          device3 = FactoryGirl.create(:device)
          post(:detach_pub_user_account, {:publisher_app_id => app_id, :publisher_user_id => user_id, :udid => device3.key})
          pub_user.udids.count.should == 2
          (pub_user.udids - [device1.key, device2.key]).should be_empty
        end
      end
    
      context 'with a valid udid' do
        it 'removes udid from user account' do
          app_id, user_id = pub_user.key.split('.')
          post(:detach_pub_user_account, {:publisher_app_id => app_id, :publisher_user_id => user_id, :udid => device1.key})
          pub_user.udids.count.should == 1
          pub_user.udids.should == [device2.key]
        end
      end
    end
  end
end
