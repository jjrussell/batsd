class Games::GamerReviewsController < GamesController
  before_filter :require_gamer

  def index
    @gamer = current_gamer
    @gamer_reviews = @gamer.gamer_reviews.ordered_by_date
  end

  def new
    @app = App.find(params[:app_id])
    @gamer_review = GamerReview.new(:app_id => params[:app_id])
    @gamer_review.user_rating = @app.user_rating
  end

  def create
    @app = App.find(params[:gamer_review][:app_id])
    @gamer_review = GamerReview.new(params[:gamer_review])
    @gamer_review.author = Gamer.find(params[:gamer_review][:author_id])
    @gamer_review.user_rating = params[:gamer_review][:user_rating].to_f > 0 ? params[:gamer_review][:user_rating].to_f : @app.user_rating
    if @gamer_review.save
      flash[:notice] = 'App review was successfully created.'
      redirect_to games_root_path
    else
      flash.now[:notice] = 'You have reviewed this app.'
      render :action => :new
    end
  end

  def edit
    @gamer_review = GamerReview.find(params[:id])
    @app = @gamer_review.app
  end

  def update
    @gamer_review = GamerReview.find(params[:id])
    @gamer_review.author = Gamer.find(params[:gamer_review][:author_id]) if params[:gamer_review][:author_id]
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
