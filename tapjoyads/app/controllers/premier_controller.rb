class PremierController < WebsiteController
  layout 'tabbed'
  current_tab :premier

  filter_access_to :all

  before_filter :set_partner
  after_filter :save_activity_logs, :only => [ :update ]

  def edit
    spend_discounts = @partner.offer_discounts.active.select{|discount| discount.source == 'Spend'}
    if @partner.exclusivity_level.nil? && spend_discounts.blank?
      if Rails.env == 'development' || request.host == 'test.tapjoy.com'
        render :action => 'new'
      end
    end
  end

  def update
    log_activity(@partner)
    if params[:agree]
      if @partner.set_exclusivity_level!(params[:partner][:exclusivity_level_type])
        flash.delete :error
        flash[:notice] = 'You have successfully updated your Tapjoy Premier level.'
      else
        flash.delete :notice
        flash[:error] = 'Your Tapjoy Premier level could not be updated.'
      end
    else
      flash.delete :notice
      flash[:error] = 'Please mark the checkbox indicating that you agree to the Tapjoy Premier terms and conditions.'
    end
    redirect_to premier_path
  end

private

  def set_partner
    @partner = current_partner
    @agreement = """
Tapjoy Premier Program

Tapjoy Premier is a membership program that gives you access to new Tapjoy features, dedicated support and pricing discounts. Benefits of the Tapjoy Premier Program include:

Access to Tapjoy Premier Support with a unique support alias and guaranteed 24-hour response time
Early beta access to new ad and site features
Discounts for Tapjoy services

By joining the Tapjoy Premier Program, you agree to enter into an exclusivity period whereby Tapjoy is the sole provider of incentivized pay-per-install services for your mobile applications. To join the program, please select your membership duration below.

If you have any questions, please contact your account manager or support@tapjoy.com
"""
  end
end
