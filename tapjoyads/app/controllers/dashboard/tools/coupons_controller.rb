class Dashboard::Tools::CouponsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  before_filter :setup, :only => [ :new, :index ]
  before_filter :find_coupon, :only => [ :show, :edit, :update, :destroy, :toggle_enabled ]
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    @coupons = @partner.coupons.visible
  end

  def new
  end

  def show
  end

  def create
    return unless verify_params([ :partner_id, :price ])
    price = sanitize_currency_param(params[:price])
    coupons = Coupon.obtain_coupons(params[:partner_id], price, params[:instructions])
    unless coupons.blank?
      coupons.each do |coupon|
        log_activity(coupon)
        coupon.save_icon!(params[:icon].read) unless params[:icon].blank?
      end
      flash[:notice] = 'Successfully created Coupons'
      redirect_to tools_coupons_path(:partner_id => params[:partner_id])
    else
      flash[:notice] = "All coupons have been retrieved at this time. <a href=\"#{tools_coupons_path(:partner_id => params[:partner_id])}\">View coupons here.</a>"
      redirect_to(new_tools_coupon_path(:partner_id => params[:partner_id])) and return
    end
  end

  def edit
  end

  def update
    icon = params[:coupon].delete("icon")
    coupon_params = sanitize_currency_params(params[:coupon],[:price])
    log_activity(@coupon)
    if @coupon.update_attributes(coupon_params)
      @coupon.save_icon!(icon.read) unless icon.blank?
      redirect_to(tools_coupons_path(:partner_id => @partner.id), :notice => 'Coupon updated successfully')
    else
      flash.now[:error] = 'Problems updating coupon offer'
      render :action => :edit
    end
  end

  def destroy
    @coupon.hide! unless @coupon.hidden?
    redirect_to(tools_coupons_path(:partner_id => @partner.id), :notice => 'Coupon has been successfully removed.')
  end

  def toggle_enabled
    @coupon.enabled = !@coupon.enabled?
    redirect_to(tools_coupons_path(:partner_id => @partner.id), :notice => "Coupon has been #{@coupon.enabled? ? 'enabled' : 'disabled'}.")
  end

  private

  def setup
    verify_params([ :partner_id ])
    @partner = Partner.find(params[:partner_id])
    verify_records([ @partner ])
  end

  def find_coupon
    @coupon = Coupon.find(params[:id])
    @partner = @coupon.partner
  end
end
