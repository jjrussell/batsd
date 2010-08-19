class OffersController < WebsiteController
  layout 'tabbed'
  filter_access_to :all
  before_filter :find_offer

  def update
    respond_to do |format|
      if @offer.update_attributes(params[:offer])
        flash[:notice] = 'Offer was successfully updated.'
        format.html { redirect_to(app_offer_path(:app_id => @app.id, :id => @offer.id)) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Update unsuccessful.'
        format.html { render :action => "show" }
        format.xml  { render :xml => @offer.errors, :status => :unprocessable_entity }
      end
    end
  end

private
  def find_offer
    @app = App.find(params[:app_id], :include => [:primary_offer])
    @offer = @app.primary_offer
  end
end
