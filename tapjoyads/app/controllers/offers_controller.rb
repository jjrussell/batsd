class OffersController < WebsiteController
  layout 'tabbed'
  filter_access_to :all
  before_filter :find_offer

  def edit
    
  end

  def update
  end

private
  def find_offer
    @app = App.find(params[:app_id], :include => [:offer])
    @offer = @app.offer
  end
end
