class OffersController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all
  before_filter :find_offer
  after_filter :save_activity_logs, :only => [ :update, :create ]
  
  def show
  end

  def update
    params_offer = sanitize_currency_params(params[:offer], [:payment])
    if @offer.safe_update_attributes(params_offer, [:daily_budget, :name, :payment, :user_enabled])
      flash[:notice] = 'Pay-per-install was successfully updated'
      redirect_to(app_offer_path(:app_id => @app.id, :id => @offer.id))
    else
      flash[:error] = 'Update unsuccessful'
      render :action => "show"
    end
  end

private
  def find_offer
    @app = current_partner.apps.find(params[:app_id], :include => [:primary_offer])
    @offer = @app.primary_offer
    log_activity(@offer)
  end
end
