class HealthzController < ActionController::Base
  newrelic_ignore

  def index
    # This should freeze the healthz app, removing it from the LB
    File.open(EPHEMERAL_HEALTHZ_FILE, 'w') do |f|
      f.write(Time.zone.now.to_i)
    end

    if File.exists?("#{Rails.root}/tmp/connect.freeze")
      render :text => 'disabled', :status => :service_unavailable
    else
      render :text => 'OK'
    end
  end

  def success
    render :template => 'layouts/success'
  end

end
