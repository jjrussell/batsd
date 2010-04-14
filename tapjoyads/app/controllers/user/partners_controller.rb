class User::PartnersController < UserController
  filter_resource_access
  
  def index
    @partners = Partner.paginate(:page => params[:page])
  end
  
  def show
  end
  
  def new
  end
  
  def create
    if @partner.save
      flash[:notice] = "Successfully created partner."
      redirect_to user_partners_path
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @partner.update_attributes(params[:partner])
      flash[:notice] = "Successfully updated partner."
      redirect_to user_partners_path
    else
      render :action => 'edit'
    end
  end
  
end
