class Tools::PayoutFreezesController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @enabled = PayoutFreeze.enabled?
    @payout_freeze = @enabled ? PayoutFreeze.enabled.first : PayoutFreeze.new
    @payout_freezes = PayoutFreeze.by_enabled_at.paginate(:page => params[:page], :per_page => 50)
  end

  def create
    @payout_freeze = PayoutFreeze.new
    @payout_freeze.enabled = true
    @payout_freeze.enabled_at = Time.zone.now
    @payout_freeze.enabled_by = current_user.username
    if @payout_freeze.save
      flash[:notice] = 'Payout freeze enabled.'
    else
      flash[:error] = 'Failed to enable payout freeze.'
    end

    redirect_to :action => :index
  end

  def disable
    @payout_freeze = PayoutFreeze.find(params[:id])
    @payout_freeze.enabled = false
    @payout_freeze.disabled_at = Time.zone.now
    @payout_freeze.disabled_by = current_user.username
    if @payout_freeze.save
      flash[:notice] = 'Payout freeze disabled.'
    else
      flash[:error] = 'Failed to disable payout freeze.'
    end

    redirect_to :action => :index
  end

end
