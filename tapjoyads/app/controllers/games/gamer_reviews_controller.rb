class Games::GamerReviewsController < GamesController
  before_filter :require_gamer

  def index
    @gamer = current_gamer
    @gamer_reviews = @gamer.gamer_reviews.ordered_by_date
  end

  def new
    @app = App.find(params[:app_id])
    @gamer_review = GamerReview.new(:app_id => params[:app_id])
    @gamer_reviews = GamerReview.paginate_all_by_app_id(@app.id, :page => params[:gamer_reviews_page])
  end

  def create
    @gamer_review = GamerReview.new(params[:gamer_review])
    @app = @gamer_review.app

    if @gamer_review.save
      flash[:notice] = 'App review was successfully created.'
      redirect_to new_games_gamer_review_path(:app_id => @app.id)
    else
      if @gamer_review.errors[:author_id].any?
        flash.now[:notice] = 'You have already reviewed this app.'
      else
        flash.now[:notice] = "There is a issue, please try again later."
      end
      @gamer_reviews = GamerReview.paginate_all_by_app_id(@app.id, :page => params[:gamer_reviews_page])
      render :action => :new
    end
  end

  def edit
    @gamer_review = GamerReview.find(params[:id])
    @app = @gamer_review.app
  end

  def update
    @gamer_review = GamerReview.find(params[:id])

    if @gamer_review.update_attributes(params[:gamer_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to games_gamer_reviews_path
    else
      render :action => :edit
    end
  end

  def destroy
    current_gamer.gamer_reviews.find(params[:id]).destroy
    redirect_to games_gamer_reviews_path
  end
end
