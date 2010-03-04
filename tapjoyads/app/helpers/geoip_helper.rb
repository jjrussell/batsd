module GeoipHelper
  include ApplicationHelper
  
  GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoLiteCity.dat")
  
  def get_geoip_data(params, request)
    data = {}
    ip_address = params[:device_ip] || get_ip_address(request)
    array = GEOIP.city(ip_address)
    
    if array
      data[:country] = array[2]
      data[:continent] = array[5]
      data[:region] = array[6]
      data[:city] = array[7]
      data[:postal_code] = array[8]
      data[:lat] = array[9]
      data[:long] = array[10]
      data[:area_code] = array[12]
    end
    
    return data
  end
  
end