class Tools::AppReviewsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_app_review, :only => [ :edit, :update, :destroy ]

  def index
    if params[:app_metadata_id]
      @app_metadata = AppMetadata.find(params[:app_metadata_id])
      @app_reviews = @app_metadata.app_reviews.ordered_by_date.paginate({:page => params[:page], :per_page=>100})
    elsif params[:author_type] && params[:author_id] && params[:author_type].match /^(Employee|Gamer)$/
      @author = params[:author_type].constantize.find(params[:author_id])
      @app_reviews = @author.app_reviews.ordered_by_date.paginate({:page => params[:page], :per_page=>100})
    else
      @app_reviews = AppReview.ordered_by_date.paginate({:page => params[:page], :per_page=>100})
    end
  end

  def search
    if params[:term].present?
      begin
        result = AppMetaData.first(:conditions=>{:id => params[:term]})
        result = AppMetaData.first(:conditions=>['name LIKE "%?%" ', params[:term]]) unless result
        render :json => result
      rescue
        render :json => { :error => true }
      end
    else
      render :json => { :error => true }
    end
  end

  def new
    @app_review = AppReview.new(:app_metadata_id => params[:app_metadata_id])
    @employees = Employee.active_by_first_name
  end

  def create
    @app_review = AppReview.new(params[:app_review])
    @app_review.author = Employee.find(params[:app_review][:author_id])
    @app_review.app_metadata = AppMetadata.find(params[:app_review][:app_metadata_id])
    if @app_review.save
      flash[:notice] = 'Successfully reviewed this app.'
      redirect_to tools_app_reviews_path(:app_metadata_id => @app_review.app_metadata_id)
    else
      if @app_review.errors[:author_id].any?
        flash.now[:error] = 'You have already reviewed this app.'
      else
        flash.now[:error] = 'There was an issue. Please try again later.'
      end
      @employees = Employee.active_by_first_name
      render :action => :new
    end
  end

  def edit
    @employees = Employee.active_by_first_name if @app_review.author_type == 'Employee'
  end

  def update
    if params[:app_review][:author_type] == 'Employee' && params[:app_review][:author_id]
      @app_review.author = Employee.find(params[:app_review][:author_id])
    end
    if @app_review.update_attributes(params[:app_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to tools_app_reviews_path(:app_metadata_id => @app_review.app_metadata_id)
    else
      @employees = Employee.active_by_first_name
      render :action => :edit
    end
  end

  def destroy
    @app_review.destroy
    redirect_to tools_app_reviews_path
  end

  private

  def find_app_review
    @app_review = AppReview.find(params[:id])
  end
end
