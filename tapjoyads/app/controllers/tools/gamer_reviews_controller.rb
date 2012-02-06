class Tools::GamerReviewsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    if params[:app_id]
      @app = App.find(params[:app_id])
      @gamer_reviews = @app.gamer_reviews.by_gamers.ordered_by_date
    elsif params[:author_id]
      @author = Gamer.find(params[:author_id])
      @gamer_reviews = @author.gamer_reviews.ordered_by_date
    else
      @gamer_reviews = GamerReview.by_gamers.ordered_by_date
    end
  end

  def edit
    @gamer_review = GamerReview.find(params[:id])
    @gamer = @gamer_review.author
  end

  def update
    @gamer_review = GamerReview.find(params[:id])

    if @gamer_review.update_attributes(params[:gamer_review])
      flash[:notice] = 'App review was successfully updated.'
      redirect_to tools_gamer_reviews_path(:app_id => @gamer_review.app_id)
    else
      render :action => :edit
    end
  end

  def destroy
    GamerReview.find(params[:id]).destroy
    redirect_to tools_gamer_reviews_path
  end
end
