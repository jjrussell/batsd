class PackageNamesController < ApplicationController
  def index
    return unless verify_params([:udid, :package_names])
    device = Device.new(:key => params[:udid])
    package_names = params[:package_names].split(',').map(&:strip).reject(&:empty?).uniq
    @call_success = true
    @new_refresh_interval = 1.week

    web_request = WebRequest.new
    web_request.put_values('package_names', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    web_request.truncated_package_names = false

    # We have a strict limit of 8KB when saving a web request.
    total_length = web_request.to_json.length.bytes + 1.kilobytes
    package_names.each do |package_name|
      total_length += (package_name.length.bytes + 3.bytes)
      if total_length > 8.kilobytes
        web_request.truncated_package_names = true
        break
      end
      web_request.package_names = package_name
    end

    begin
      device.update_package_names!(package_names)
      web_request.save
    rescue
      @call_success = false
      @new_refresh_interval = 1.day
    end
  end
end
