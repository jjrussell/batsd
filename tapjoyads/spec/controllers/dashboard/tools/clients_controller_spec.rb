require 'spec_helper'

describe Dashboard::Tools::ClientsController do
  before :each do
    activate_authlogic
    login_as(FactoryGirl.create(:account_manager_user))
    @client = FactoryGirl.create(:client, :name => 'BBB')
    @client2 = FactoryGirl.create(:client, :name => 'AAA')
    @partner = FactoryGirl.create(:partner, :client => @client)
    @partner2 = FactoryGirl.create(:partner)
  end

  describe '#index' do
    it 'returns all clients ordered by name' do
      get(:index)
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
      it 'flashes a notice' do
        flash[:notice].should == 'Client created'
      end

      it 'redirects to clients index' do
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

      it 'redirects to tools/clients' do
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
        request.env['HTTP_REFERER'] = tools_client_path(@client2)
        put(:add_partner, @options)
      end

      it 'redirects to client show page' do
        response.should redirect_to(tools_client_path(@client2))
      end

      it 'associates partner with client' do
        @partner2.reload
        @partner2.client.should == @client2
      end
    end

    context 'when partner already associated with another client' do
      before :each do
        @options = {
          :id => @client2.id,
          :partner_id => @partner.id
        }
        request.env['HTTP_REFERER'] = tools_client_path(@client2)
        put(:add_partner, @options)
      end

      it 'sets an error' do
        flash[:error].should == ["Client cannot be switched to another client."]
      end

      it 'redirects to client show page' do
        response.should redirect_to(tools_client_path(@client2))
      end

      it 'does not associate partner with client' do
        @partner.client.should == @client
        @client2.partners.should be_empty
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
        request.env['HTTP_REFERER'] = tools_client_path(@client)
        put(:remove_partner, @options)
      end

      it 'redirects to client show page' do
        response.should redirect_to(tools_client_path(@client))
      end

      it 'disassociates partner with client' do
        @partner.reload
        @partner.client.should be_nil
        @client.partners.should be_empty
      end
    end
  end

end
