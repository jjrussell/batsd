module Games::AppReviews::ModerationModule
  def create
    gamer_review = current_gamer.app_reviews.find_by_id( params[:app_review_id]) # nil when not found
    review = AppReview.find_by_id params[:app_review_id]
    case
    when gamer_review.present?
      render :json => {:msg => "Can't flag own review"}, :status => 401
    when review.nil?
      render :json => {:msg => "Can't find review to flag"}, :status => 404
    when current_gamer_votes.exists?(:app_review_id => params[:app_review_id])
      render :json => {:msg => "Already flagged"}, :status => 200
    when result = current_gamer_votes.build(post_params).save
      render :json => {:msg => verb, :class=>yes_class }, :status => 201
    else
      render :json => {:msg => "Failed for unknown reason"}, :status => 403
    end
  end


  def destroy
    flag = current_gamer_votes.find_by_app_review_id params[:app_review_id]
    case
    when flag.nil?
      render :json => {:msg => "Can't find flag to remove, or not your flag to remove"}, :status => 404
    when result = flag.destroy
      render :json => {:msg => "Flag Removed."}, :status => 200
    else
      render :json => {:msg => "Failed for unknown reason"}, :status => 403
    end
  end
end
