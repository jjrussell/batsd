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
  
  PERMISSIONS_MAP = {
    :detach_pub_user_account => {
      :permissions => {
        :account_manager          => false,
        :admin                    => false,
        :agency                   => false,
        :customer_service         => false,
        :customer_service_manager => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_changer          => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },

    :index => {
      :permissions => {
        :account_manager          => true,
        :admin                    => true,
        :agency                   => false,
        :customer_service         => true,
        :customer_service_manager => true,
        :devices                  => true,
        :executive                => true,
        :file_sharer              => true,
        :games_editor             => true,
        :hr                       => true,
        :money                    => true,
        :ops                      => false,
        :products                 => true,
        :partner                  => false,
        :partner_changer          => true,
        :payops                   => true,
        :payout_manager           => true,
        :reporting                => false,
        :role_manager             => true,
        :sales_rep_manager        => true,
        :tools                    => true
      }
    },
      
    :partner_monthly_balance => {
      :permissions => {
        :account_manager          => false,
        :admin                    => true,
        :agency                   => false,
        :customer_service         => false,
        :customer_service_manager => false,
        :devices                  => false,
        :executive                => true,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_changer          => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },
    
    :partner_monthly_balance => {
      :permissions => {
        :account_manager          => false,
        :admin                    => true,
        :agency                   => false,
        :customer_service         => false,
        :customer_service_manager => false,
        :devices                  => false,
        :executive                => true,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_changer          => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },
    
    :view_pub_user_account => {
      :permissions => {
        :account_manager          => false,
        :admin                    => false,
        :agency                   => false,
        :customer_service         => false,
        :customer_service_manager => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_changer          => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    }
  } unless defined? PERMISSIONS_MAP

  it_behaves_like "a controller with permissions"
  
  describe '#partner_monthly_balance' do
    context 'with an admin user' do
      include_context 'logged in as user type', :admin
    
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
      include_context 'logged in as user type', :customer_service_manager
      
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
      include_context 'logged in as user type', :customer_service_manager
      
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

    describe "#device_info" do
      before :each do
        click = Click.new(:key => FactoryGirl.generate(:guid), :consistent => true)
        click.clicked_at = Time.now-1.day
        click.save
        @device1.add_click(click)
      end

      it "should pass with valid parameters passed in", :device_info do
        app_id, user_id = @pub_user.key.split('.')
        post(:device_info, {:publisher_app_id => app_id, :publisher_user_id => user_id,
                            :udid => @device1.key})
      end

      it "should pass with cutoff date passed in", :device_info do
        app_id, user_id = @pub_user.key.split('.')
        post(:device_info, {:publisher_app_id => app_id, :publisher_user_id => user_id,
                            :cut_off_date => (Time.now-1.month).to_i, :udid => @device1.key})
      end
    end
  end
end
