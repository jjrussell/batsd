class Dashboard::Tools::RejectionsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    if Offer.exists?(params[:offer_id])
      @offer = Offer.find(params[:offer_id])
      app = App.find(@offer.app_id) if @offer.app_id.present?
      device = Device.find(params[:device_id]) if params[:device_id].present?
      geoip_data = {:primary_country => params[:primary_country]}
      currency = Currency.find(params[:currency_id]) if Currency.exists?(params[:currency_id])
      @rejections = @offer.postcache_rejections(app, device, currency, params[:device_type],
                    geoip_data, params[:app_version], params[:direct_pay_providers], params[:offer_type],
                    params[:hide_rewarded_app_installs], params[:library_version], params[:os_version],
                    params[:video_offer_ids], params[:source], params[:all_videos], params[:store_whitelist],
                    params[:store_name])
    end
  end
end
