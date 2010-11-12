class PremierController < WebsiteController
  layout 'tabbed'
  current_tab :premier

  filter_access_to :all

  before_filter :set_partner
  after_filter :save_activity_logs, :only => [ :update ]

  def edit
    if @partner.exclusivity_level.nil?
      if Rails.env == 'development' || request.host == 'test.tapjoy.com'
        render :action => 'new'
      end
    end
  end

  def update
    log_activity(@partner)
    if @partner.set_exclusivity_level! params[:partner][:exclusivity_level_type]
      flash[:notice] = 'You have successfully updated your Tapjoy Premier level.'
    else
      flash[:error] = 'Your Tapjoy Premier level could not be updated.'
    end
    render :edit
  end

private

  def set_partner
    @partner = current_partner
  end
end
