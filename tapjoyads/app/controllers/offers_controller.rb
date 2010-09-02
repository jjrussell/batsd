class OffersController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all
  before_filter :find_offer

  def update
    params_offer = sanitize_currency_params(params[:offer], [:daily_budget, :payment])
    respond_to do |format|
      if @offer.safe_update_attributes(params_offer, [:daily_budget, :name, :payment, :user_enabled])
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
    @app = current_partner.apps.find(params[:app_id], :include => [:primary_offer])
    @offer = @app.primary_offer
  end
end
