class PackageNamesController < ApplicationController
  def index
    return unless verify_params([:udid, :package_names])
    device = Device.new(:key => params[:udid])
    if device.new_record?
      render :text => "invalid device", :status => 400
      return
    end

    package_names = params[:package_names].split(',').map(&:strip).reject(&:empty?).uniq

    web_request = WebRequest.new
    web_request.put_values('package_names', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    package_names.each do |package_name|
      web_request.package_names = package_name
    end
    web_request.save

    device.update_package_names!(package_names)
    @new_refresh_interval = 1.week
  end
end
