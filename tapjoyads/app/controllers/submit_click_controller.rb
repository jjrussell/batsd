class SubmitClickController < ApplicationController

  def store
    render(:template => 'layouts/success')
  end

  def offer
    render(:template => 'layouts/success')
  end

  def ad
    return unless verify_params([:campaign_id, :app_id, :udid])

    web_request = WebRequest.new
    web_request.put_values('adclick', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    web_request.save

    render(:template => 'layouts/success')
  end
end
