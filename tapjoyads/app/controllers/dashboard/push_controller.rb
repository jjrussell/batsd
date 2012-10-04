class Dashboard::PushController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps
  before_filter :setup

  #used to enable push admin option. Just TapDefense ios and android
  #TDOD - implement permanent solution
  BETA_PUSH_NOTIFICATION_APPS = ["30091aa4-9ff3-4717-a467-c83d83f98d6d", "2349536b-c810-47d7-836c-2cd47cd3a796"]

private
  def setup
    @app = find_app(params[:app_id])
    @admin_url = "#{notifications_url_base}/admin/apps/#{@app.id}/edit?platform=#{@app.platform}&signature=#{signature}&signature_method=hmac_sha256"
  end
  
  def signature
    Signage::Signature.new('hmac_sha256', Rails.application.config.notifications_secret).sign({:id => @app.id, :platform => @app.platform})
  end
  
  def notifications_url_base
    Rails.application.config.notifications_url
  end
end
