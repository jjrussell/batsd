require 'net/http'

class GetadController < ApplicationController
  def adfonic
    respond_to do |f|  
      @ad_return_obj = TapjoyAd.new
      @ad_return_obj.ClickURL = 'http://sample.com'
      @ad_return_obj.Image = '9823897239487239487'
      f.xml {render(:partial => 'tapjoy_ad')}
    end
  end
  
  def crisp
    respond_to do |f|
      partner_key = params[:partner_key]
      site_key = params[:site_key]
      zone_key = params[:zone_key]
      user_agent = request.headers['User-Agent']
           
      host = 'api.crispwireless.com'
      path = "/adRequest.v1/single/ad.html" +
          "?partnerkey=#{partner_key}" + 
          "&sitekey=#{site_key}" +
          "&random=#{rand(9999999)}" +
          "&rspid=" +
          "&zonekey=#{zone_key}" +
          "&sectionkey"
      
      html = ''
      Net::HTTP.start(host) do |http|
        html = http.get(path, "User-Agent" =>user_agent).body
      end
      
      if html.include? 'Error: Empty ad'
        @ad_return_obj = nil
        f.html {render(:text => "no ad")}
      else
        @ad_return_obj = TapjoyAd.new
        @ad_return_obj.ClickURL = host + path
        @ad_return_obj.AdHTML = html
        f.xml {render(:partial => 'tapjoy_ad')}
      end
    end
  end
  
end
