class HealthzController < ActionController::Base

  def index
    # This should freeze the healthz app, removing it from the LB
    File.open(EPHEMERAL_HEALTHZ_FILE, 'w') do |f|
      f.write(Time.zone.now.to_i)
    end

    render :text => "OK"
  end

  def success
    render :template => 'layouts/success'
  end

end
