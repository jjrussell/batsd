class Tools::AppReviewsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @app_reviews = AppReview.by_employees
  end

  def new
    @app_review = AppReview.new
    @app_id = params[:app_id]
    @employee_ids = Employee.active_only.collect { |emp| [ emp.full_name, emp.id ] }
  end

  def create
    @app_review = AppReview.new(params[:app_review])
    @app_review.author = Employee.find(params[:app_review][:author_id])
    if @app_review.save
      flash[:notice] = 'App review was successfully created.'
      redirect_to tools_app_review_path(@app_review.app_id)
    else
      render :action => :new
    end
  end

  def show
    @app = App.find(params[:id])
    @app_reviews = @app.app_reviews.by_employees
  end

  def edit
    @app_review = AppReview.find(params[:id])
    @app_ids = App.all.collect { |app| [ app.name, app.id ] }
    @employee_ids = Employee.active_only.collect { |emp| [ emp.full_name, emp.id ] }
  end

  def update
    @app_review = AppReview.find(params[:id])
    @app_review.author = Employee.find(params[:app_review][:author_id]) if params[:app_review][:author_id]
    if @app_review.update_attributes(params[:app_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to tools_app_reviews_path
    elsif params[:app_review][:author_id]
      render :action => :edit
    else
      flash[:error] = "Sorry, that date already has an app featured on it"
      redirect_to tools_app_reviews_path
    end
  end

  def destroy
    AppReview.find(params[:id]).destroy
    redirect_to tools_app_reviews_path
  end
end
