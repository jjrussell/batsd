class ImpressionController < ApplicationController
  before_filter :decrypt_data_param
  def index
    headers['Last-Modified'] = Time.now.httpdate
    render :text => "\x47\x49\x46\x38\x39\x61\x1\x0\x1\x0\x80\xff\x0\xc0\xc0\xc0\x0\x0\x0\x21\xf9\x4\x1\x0\x0\x0\x0\x2c\x0\x0\x0\x0\x1\x0\x1\x0\x0\x1\x1\x32\x0\x3b", :content_type => 'image/gif'  # Hex for transparent 1x1 GIF
    web_request = WebRequest.new(:time => Time.zone.now)
    case params[:type]
      when Offer::FEATURED_OFFER_TYPE
        wr_path = 'featured_offer_rendered'
      when Offer::DISPLAY_OFFER_TYPE
        wr_path = 'display_ad_rendered'
    end
    web_request.put_values(wr_path, params, ip_address, geoip_data, request.headers['User-Agent'])
    web_request.save
  end

  private


end
