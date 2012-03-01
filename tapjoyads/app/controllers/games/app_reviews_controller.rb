class Games::AppReviewsController < GamesController
  before_filter :require_gamer
  before_filter :find_app_review, :only => [ :edit, :update, :destroy ]

  def index
    if params[:gamer_id]
      @gamer = Gamer.find_by_id(params[:gamer_id])
      @app_reviews = @gamer ? @gamer.app_reviews.ordered_by_date : []
    else
      @gamer = current_gamer
      @app_reviews = @gamer.app_reviews.ordered_by_date
    end
  end

  def new
    @app = AppMetadataMapping.find_by_app_metadata_id(params[:app_metadata_id]).app
    @app_metadata = @app.primary_app_metadata
    @app_review = current_gamer.review_for(@app_metadata.id) || @app_metadata.app_reviews.build(:user_rating => 1)
  end

  def create
    @app_review = AppReview.new(params[:app_review])
    @app_review.author = current_gamer
    @app_review.author_type = 'Gamer'
    @app_id = @app_review.app_metadata.apps.first

    if @app_review.save
      flash[:notice] = t('text.games.review_created')
    else
      if @app_review.errors[:author_id].any?
        flash.now[:error] = t("text.games.reviewed_already")
      else
        flash.now[:error] = t("text.games.review_issue")
      end
    end

    redirect_to games_earn_path(:eid => ObjectEncryptor.encrypt(@app_id))
  end

  def edit
    @app_metadata = @app_review.app_metadata
  end

  def update
    if @app_review.update_attributes(params[:app_review])
      app_id = AppMetadataMapping.find_by_app_metadata_id(@app_review.app_metadata_id).app_id
      flash[:notice] = t('text.games.review_updated')
      redirect_to games_earn_path(:eid => ObjectEncryptor.encrypt(app_id))
    else
      render :action => :edit
    end
  end

  def destroy
    @app_review.destroy
    redirect_to games_app_reviews_path
  end

  private

  def find_app_review
    @app_review = current_gamer.app_reviews.find(params[:id])
  end
end
