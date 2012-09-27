class Dashboard::PushController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps
  before_filter :setup
  
  BETA_PUSH_NOTIFICATION_APPS = []

private
  def setup
    @app = find_app(params[:app_id])
    @admin_url = "#{notifications_url_base}/admin/apps/#{@app.id}/edit?platform=#{@app.platform}&signature=#{signature}&signature_method=hmac_sha256"
  end
  
  def signature
    Signage::Signature.new('hmac_sha256', Rails.application.config.signage_secret).sign({:id => @app.id, :platform => @app.platform})
  end
  
  def notifications_url_base
    Rails.application.config.notifications_url
  end
end
