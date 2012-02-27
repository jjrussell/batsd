require 'spec/spec_helper'

describe Tools::ClientsController do
  before :each do
    fake_the_web
    activate_authlogic
    account_mgr_user = Factory(:account_mgr_user)
    login_as(account_mgr_user)
    @client = Factory(:client, :name => 'BBB')
    @client2 = Factory(:client, :name => 'AAA')
    @partner = Factory(:partner)
    @partner.update_attributes({ :client_id => @client.id })
    @partner2 = Factory(:partner)
  end

  describe '#index' do
    it 'returns all clients order by name' do
      get :index
      assigns[:clients].should == [ @client2, @client ]
    end
  end

  describe '#create' do
    before :each do
      @options = {
        :client => {
          :name => 'glu'
        }
      }
      post(:create, @options)
    end

    context 'when client does not exist' do
      it 'creates a client' do
        flash[:notice].should == 'Client created'
        response.should redirect_to(tools_clients_path)
      end
    end

    context 'when the client already exists' do
      it 'renders tools/clients/new' do
        post(:create, @options)
        response.should render_template('tools/clients/new')
      end
    end
  end

  describe '#edit' do
    before :each do
      get(:edit, :id => @client.id)
    end

    context 'when edit succeeds' do
      it 'gets the client' do
        assigns[:client].should == @client
      end
    end
  end

  describe '#update' do
    before :each do
      @options = {
        :id => @client.id,
        :client => {
          :name => 'CCC'
        }
      }
      put(:update, @options)
    end

    context 'when update succeeds' do
      it 'updates the name of client' do
        assigns[:client].name.should == 'CCC'
      end

      it 'sets a notice' do
        flash[:notice].should == 'Client saved'
      end

      it "redirects to tools/clients" do
        response.should redirect_to(tools_clients_path)
      end
    end
  end

  describe '#show' do
    before :each do
      get(:show, :id => @client.id)
    end

    it 'gets the client' do
      assigns[:client].should == @client
    end

    it 'finds all partners associated with the client' do
      assigns[:client].partners.should == [ @partner ]
    end
  end

  describe '#add_partner' do
    context 'when add_partner succeeds' do
      before :each do
        @options = {
          :id => @client2.id,
          :partner_id => @partner2.id
        }
        request.env["HTTP_REFERER"] = add_partner_tools_client_path(@client2)
        put(:add_partner, @options)
      end

      it "redirects to client show page" do
        response.should redirect_to(add_partner_tools_client_path(@client2))
      end

      it 'associates partner with client' do
        @partner2.reload
        @partner2.client.should == @client2
      end
    end

    context 'when partner already associated with another client, add_partner fails' do
      before :each do
        @options = {
          :id => @client2.id,
          :partner_id => @partner.id
        }
        request.env["HTTP_REFERER"] = add_partner_tools_client_path(@client2)
        put(:add_partner, @options)
      end

      it 'sets a error' do
        flash[:error].should == "partner #{@partner.name} already associated with client #{@client.name}"
      end

      it "redirects to client show page" do
        response.should redirect_to(add_partner_tools_client_path(@client2))
      end

      it 'does not associate partner with client' do
        @partner.client.should == @client
        @client2.partners.should == []
      end
    end
  end

  describe '#remove_partner' do
    context 'when remove_partner succeeds' do
      before :each do
        @options = {
          :id => @client.id,
          :partner_id => @partner.id
        }
        request.env["HTTP_REFERER"] = add_partner_tools_client_path(@client)
        put(:remove_partner, @options)
      end

      it "redirects to client show page" do
        response.should redirect_to(add_partner_tools_client_path(@client))
      end

      it 'disassociates partner with client' do
        @partner.reload
        @partner.client.should == nil
        @client.partners.should == []
      end
    end
  end

end
