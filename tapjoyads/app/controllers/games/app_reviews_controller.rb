class Games::AppReviewsController < GamesController
  before_filter :require_gamer

  def index
    @gamer = current_gamer
    @app_reviews = @gamer.app_reviews.ordered_by_date
  end

  def new
    @app = App.find(params[:app_id])
    @app_review = AppReview.new(:app_id => params[:app_id])
    @app_reviews = AppReview.paginate_all_by_app_id(@app.id, :page => params[:app_reviews_page])
  end

  def create
    @app_review = AppReview.new(params[:app_review])
    @app = @app_review.app

    if @app_review.save
      flash[:notice] = 'App review was successfully created.'
      redirect_to new_games_app_review_path(:app_id => @app.id)
    else
      if @app_review.errors[:author_id].any?
        flash.now[:notice] = 'You have already reviewed this app.'
      else
        flash.now[:notice] = "There is a issue, please try again later."
      end
      @app_reviews = AppReview.paginate_all_by_app_id(@app.id, :page => params[:app_reviews_page])
      render :action => :new
    end
  end

  def edit
    @app_review = AppReview.find(params[:id])
    @app = @app_review.app
  end

  def update
    @app_review = AppReview.find(params[:id])

    if @app_review.update_attributes(params[:app_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to games_app_reviews_path
    else
      render :action => :edit
    end
  end

  def destroy
    current_gamer.app_reviews.find(params[:id]).destroy
    redirect_to games_app_reviews_path
  end
end
