class Tools::BrandsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @brands = Brand.all
  end

  def new
    @brand = Brand.new
  end

  def edit
    @brand = Brand.find(params[:id], :include => :offers)
  end

  def create
    @brand = Brand.new(:name => params[:brand][:name])
    if @brand.save
      flash[:notice] = 'Successfully created Brand'
      redirect_to tools_brands_path
    else
      flash[:error] = 'Brand was not saved'
      render :action => :new
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

 end
