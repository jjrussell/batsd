class Tools::BrandsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @brands = Brand.all(:order => 'name ASC').paginate(:page => params[:page], :per_page => 200)
  end

  def new
    @brand = Brand.new
  end

  def edit
    @brand = Brand.find(params[:id], :include => :offers)
  end

  def create
    @brand = Brand.new(:name => params[:brand][:name])
    success = @brand.save

    respond_to do |format|
      format.html do
        if success
          flash[:notice] = 'Successfully created Brand'
          redirect_to tools_brands_path
        else
          flash[:error] = 'Brand was not saved'
          render :action => :new
        end
      end
      format.json do
        json = { :success => success, :brand => { :name => @brand.name, :id => @brand.id } }
        json.merge!({:error => @brand.errors.first}) unless success
        render(:json => json)
      end
    end
  end

  def update
    @brand = Brand.find(params[:id], :include => :offers)
    if @brand.update_attributes(params[:brand])
      flash[:notice] = 'Successfully updated'
      redirect_to tools_brands_path
    else
      flash[:error] = 'Unsuccessful'
      render :action => :edit
    end
  end

  def show
    @brand = Brand.find(params[:id])
    respond_to do |format|
      format.js do
        offers = []
        @brand.offers.each do |offer|
          offers << {:id => offer.id, :name => offer.search_result_name }
        end
        render(:json => offers.to_json)
      end
    end
  end
end
