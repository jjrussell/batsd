class PremierController < WebsiteController
  layout 'tabbed'
  current_tab :premier

  filter_access_to :all

  before_filter :set_partner
  before_filter :nag_user_about_payout_info
  after_filter :save_activity_logs, :only => [ :update ]

  def edit
    @is_new = !@partner.is_premier?

    if @is_new || @partner.exclusivity_level.nil?
      @levels = ExclusivityLevel::TYPES
      @default_level = @levels.last
    else
      @levels = ExclusivityLevel::TYPES.reject{|t| t.constantize.new.months < @partner.exclusivity_level.months}
      @default_level = @levels.first
    end
    @levels = @levels.map{|t|[t.underscore.humanize.pluralize, t]}
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
