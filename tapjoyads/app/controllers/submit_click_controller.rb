class SubmitClickController < ApplicationController
  before_filter :lookup_device, :only => [ :ad ]

  def store
    render(:template => 'layouts/success')
  end

  def offer
    render(:template => 'layouts/success')
  end

  def ad
    return unless verify_params([:campaign_id, :app_id, :tapjoy_device_id])

    web_request = WebRequest.new
    web_request.put_values('adclick', params, ip_address, geoip_data, request.headers['User-Agent'])
    web_request.save

    render(:template => 'layouts/success')
  end
end
