class OfferCreativesController < WebsiteController
  layout 'simple'

  filter_access_to :all
  before_filter :setup

  def show
    @creative_exists = @offer.banner_creatives.include?(@image_size)

    @success_message = params.delete(:success_message)
    @error_message = params.delete(:error_message)
  end

  def create
    @offer.banner_creatives += @image_size.to_a
    update # yup
  end

  def update
    @offer.send("banner_creative_#{@image_size}_blob=", image_data)
    @success = @offer.save

    return_to_form
  end

  def destroy
    @offer.banner_creatives -= @image_size.to_a
    @success = @offer.save

    return_to_form
  end

  private
  def setup
    @image_size = params[:image_size]
    @label = params[:label]
    @offer = Offer.find(params[:id])

    if params.key?(:app_id)
      @app = App.find(params[:app_id])
      @preview_path = preview_app_offer_path(:id => @offer.id, :image_size => @image_size, :preview => true, :app_id => @app.id)
    end

    log_activity(@offer)
  end

  def image_data
    params[:offer]["custom_creative_#{@image_size}".to_sym].read
  end

  def return_to_form
    redir = {
      :action => :show,
      :id => @offer.id,
      :image_size => @image_size,
      :label => @label
    }
    redir[:app_id] = @app.id if @app

    if @success === true
      redir[:success_message] = "File #{request.method == :delete ? 'removed' : 'uploaded'} successfully."
    elsif @success === false
      redir[:error_message] = @offer.errors["custom_creative_#{@image_size}_blob".to_sym]
    end

    redirect_to redir
  end
end
