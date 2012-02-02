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
    @app = App.find(params[:gamer_review][:app_id])
    @gamer_review = GamerReview.new(params[:gamer_review])
    @gamer_review.prev_rating = 0
    @gamer_review.user_rating = params[:gamer_review][:user_rating].to_i != 0 ? params[:gamer_review][:user_rating].to_i : 0

    if GamerReview.find_by_author_id_and_app_id(current_gamer.id, params[:gamer_review][:app_id])
      flash.now[:notice] = 'You have already reviewed this app.'
      @gamer_reviews = GamerReview.paginate_all_by_app_id(@app.id, :page => params[:gamer_reviews_page])
      render :action => :new
      return
    end

    if @gamer_review.save
      flash[:notice] = 'App review was successfully created.'
      redirect_to new_games_gamer_review_path(:app_id => params[:gamer_review][:app_id])
    else
      flash.now[:notice] = "There is a issue, please try again later."
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
    params[:gamer_review][:prev_rating] = @gamer_review.user_rating ? @gamer_review.user_rating : 0

    if @gamer_review.update_attributes(params[:gamer_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to games_gamer_reviews_path
    else
      render :action => :edit
    end
  end

  def destroy
    GamerReview.find(params[:id]).destroy
    redirect_to games_gamer_reviews_path
  end
end
