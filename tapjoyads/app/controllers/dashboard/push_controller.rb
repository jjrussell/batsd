class Dashboard::PushController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps
  before_filter :setup

  #Used to enable push admin option. Temporary list for us to use internally for our beta period.
  BETA_PUSH_NOTIFICATION_APPS = ["30091aa4-9ff3-4717-a467-c83d83f98d6d", "2349536b-c810-47d7-836c-2cd47cd3a796", "f6634505-b442-42fc-a359-db3fd926b42d"]

  def update
    @app.notifications_enabled = params[:app][:notifications_enabled]

    begin
      @app.transaction do
        @app.save!
        notification_app.update if @app.notifications_enabled?
      end
      flash[:notice] = "Push notifications have been #{@app.notifications_enabled? ? 'enabled' : 'disabled'}"
      redirect_to :action => "index"
    rescue Exception => e
      Airbrake.notify(e)
      flash[:error] = "There was a problem updating this app"
      redirect_to :action => "index"
    end
  end

private
  def notification_app
    NotificationsClient::App.new({
      :app_id => @app.id,
      :app => {
        :secret_key => @app.secret_key,
        :platform => @app.platform,
        :name => @app.name
      }
    })
  end

  def setup
    @app = find_app(params[:app_id])
    @admin_url = "#{notifications_url_base}/admin/apps/#{@app.id}/edit?signature=#{signature}&signature_method=hmac_sha256"
  end

  def signature
    Signage::Signature.new('hmac_sha256', Rails.application.config.notifications_secret).sign({:id => @app.id})
  end

  def notifications_url_base
    Rails.application.config.notifications_url
  end
end
