class Dashboard::Tools::OfferIconsController < Dashboard::DashboardController
  filter_access_to :all

  layout 'simple'
  before_filter :find_offer

  def create
    update
  end

  def edit
  end

  def update
    image_data = params[:offer][:upload_icon].try(:read)
    begin
      @offer.save_icon!(image_data, true)
      @success_message = "Icon uploaded successfully."
    rescue
      @error_message = "Error uploading icon, please try again."
    end
    render :edit
  end

  def destroy
    begin
      @offer.remove_overridden_icon!
      @success_message = "Icon removed successfully."
    rescue
      @error_message = "Error removing icon, please try again."
    end
    render :edit
  end

  private

  def find_offer
    @offer = Offer.find(params[:id])
  end
end
