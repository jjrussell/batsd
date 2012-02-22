class Tools::AppReviewsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    if params[:app_metadata_id]
      @app_metadata = AppMetadata.find(params[:app_metadata_id])
      @app_reviews = @app_metadata.app_reviews.ordered_by_date
    elsif params[:author_type] == 'Employee' && params[:author_id]
      @author = Employee.find(params[:author_id])
      @app_reviews = @author.app_reviews.ordered_by_date
    elsif params[:author_type] == 'Gamer' && params[:author_id]
      @author = Gamer.find(params[:author_id])
      @app_reviews = @author.app_reviews.ordered_by_date
    else
      @app_reviews = AppReview.ordered_by_date
    end
  end

  def new
    @app_review = AppReview.new(:app_metadata_id => params[:app_metadata_id])
    @employees = Employee.active_by_first_name
  end

  def create
    @app_review = AppReview.new(params[:app_review])
    @app_review.author = Employee.find(params[:app_review][:author_id])
    if @app_review.save
      flash[:notice] = 'App review was successfully created.'
      redirect_to tools_app_reviews_path(:app_id => @app_review.app_id)
    else
      if @app_review.errors[:author_id].any?
        flash.now[:error] = 'You have already reviewed this app.'
      else
        flash.now[:error] = "There is an issue, please try again later."
      end
      @employees = Employee.active_by_first_name
      render :action => :new
    end
  end

  def edit
    @app_review = AppReview.find(params[:id])
    @employees = Employee.active_by_first_name if @app_review.author_type == 'Employee'
  end

  def update
    @app_review = AppReview.find(params[:id])
    if params[:app_review][:author_type] == 'Employee' && params[:app_review][:author_id]
      @app_review.author = Employee.find(params[:app_review][:author_id])
    end
    if @app_review.update_attributes(params[:app_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to tools_app_reviews_path(:app_id => @app_review.app_id)
    else
      @employees = Employee.active_by_first_name
      render :action => :edit
    end
  end

  def destroy
    AppReview.find(params[:id]).destroy
    redirect_to tools_app_reviews_path
  end
end
