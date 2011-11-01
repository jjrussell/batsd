class HealthzController < ActionController::Base

  def index
    # this is just here so health-checks fail if the PRNG is not properly seeded
    UUIDTools::UUID.random_create

    render :text => "OK"
  end

  def success
    render :template => 'layouts/success'
  end

end
