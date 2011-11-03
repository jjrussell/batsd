class HealthzController < ActionController::Base

  def index
    render :text => "OK"
  end

  def success
    render :template => 'layouts/success'
  end

end
