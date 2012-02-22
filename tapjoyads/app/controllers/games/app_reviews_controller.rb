class Games::AppReviewsController < GamesController
  before_filter :require_gamer
  before_filter :app_review, :only => [ :edit, :update, :destroy ]

  def index
    if params[:gamer_id]
      @gamer = Gamer.find_by_id(params[:gamer_id])
      @app_reviews = @gamer ? @gamer.app_reviews.ordered_by_date : []
    elsif params[:app_metadata_id]
      @app = App.find_by_id(AppMetadataMapping.find_by_app_metadata_id(params[:app_metadata_id]).app_id)
      @app_metadata = @app.primary_app_metadata
      @app_review = current_gamer.review_for(@app_metadata.id) || @app_metadata.app_reviews.build
      @app_reviews = AppReview.by_gamers.paginate_all_by_app_metadata_id(@app_metadata.id, :page => params[:app_reviews_page])
      render :new and return
    else
      @gamer = current_gamer
      @app_reviews = @gamer.app_reviews.ordered_by_date
    end
  end

  def create
    @app_review = AppReview.new(params[:app_review])
    @app_metadata = @app_review.app_metadata

    if @app_review.save
      flash[:notice] = 'Successfully reviewed this app.'
      redirect_to games_app_reviews_path(:app_metadata_id => @app_metadata.id)
    else
      if @app_review.errors[:author_id].any?
        flash.now[:error] = 'You have already reviewed this app.'
      else
        flash.now[:error] = 'There was an issue. Please try again later.'
      end
      @app_reviews = AppReview.paginate_all_by_app_metadata_id(@app_metadata.id, :page => params[:app_reviews_page])
      params[:app_metadata_id] = @app_metadata.id
      @app = App.find_by_id(AppMetadataMapping.find_by_app_metadata_id(@app_metadata.id).app_id)
      render :action => :index
    end
  end

  def edit
    @app_metadata = @app_review.app_metadata
  end

  def update
    if @app_review.update_attributes(params[:app_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to request.env['HTTP_REFERER'] and return if request.env['HTTP_REFERER']
      redirect_to games_app_reviews_path
    else
      render :action => :edit
    end
  end

  def destroy
    @app_review.destroy
    redirect_to games_app_reviews_path
  end

  private

  def app_review
    @app_review = current_gamer.app_reviews.find(params[:id])
  end
end
