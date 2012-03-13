class Tools::ClientsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @page_title = 'Clients'
    @clients = Client.ordered_by_name
  end

  def new
    @page_title = 'Create Client'
    @client = Client.new
  end

  def create
    @page_title = 'Create Client'
    @client = Client.new(params[:client])
    if @client.save
      flash[:notice] = 'Client created'
      redirect_to tools_clients_path
    else
      render :action => :new
    end
  end

  def edit
    @page_title = 'Edit client'
    @client = Client.find(params[:id])
  end

  def show
    @client = Client.find(params[:id])
    @page_title = "Client: #{@client.name}"
  end

  def update
    @client = Client.find(params[:id])
    if @client.safe_update_attributes( params[:client], [ :name ] )
      flash[:notice] = 'Client saved'
      redirect_to tools_clients_path
    else
      render :action => :edit
    end
  end

  def add_partner
    client_id = params[:id]
    partner = Partner.find(params[:partner_id])
    if partner.client.present?
      flash[:error] = "partner #{partner.name} already associated with client #{partner.client.name}"
    else
      partner.update_attribute(:client_id, client_id)
    end
    redirect_to :back
  end

  def remove_partner
    partner = Partner.find(params[:partner_id])
    partner.update_attribute(:client_id, nil)
    redirect_to :back
  end

end
