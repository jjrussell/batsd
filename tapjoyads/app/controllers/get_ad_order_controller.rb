class GetAdOrderController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid])

    render :template => 'layouts/success'
  end
end