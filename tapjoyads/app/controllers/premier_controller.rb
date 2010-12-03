class PremierController < WebsiteController
  layout 'tabbed'
  current_tab :premier

  filter_access_to :all

  before_filter :set_partner
  after_filter :save_activity_logs, :only => [ :update ]

  def edit
    spend_discounts = @partner.offer_discounts.active.select{|discount| discount.source == 'Spend'}
    if @partner.exclusivity_level.nil? && spend_discounts.blank?
      render :action => 'new'
    end
  end

  def update
    log_activity(@partner)
    if params[:agree]
      new_premier = @partner.exclusivity_level.nil?
      if @partner.set_exclusivity_level!(params[:partner][:exclusivity_level_type])
        flash.delete :error
        flash[:notice] = new_premier ? 'You have successfully joined Tapjoy Premier!' : 'You have successfully renewed your Tapjoy Premier membership!'
      else
        flash.delete :notice
        flash[:error] = 'Your Tapjoy Premier membership status could not be changed.'
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
  end
end
