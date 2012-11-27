class PackageNamesController < ApplicationController

  before_filter :lookup_device

  def index
    return unless verify_params([:tapjoy_device_id, :package_names])
    device = find_or_create_device
    package_names = params[:package_names].split(',').map(&:strip).reject(&:empty?).uniq
    @call_success = true
    @new_refresh_interval = 1.week

    web_request = WebRequest.new
    web_request.put_values('package_names', params, ip_address, geoip_data, request.headers['User-Agent'])

    package_names.each do |package_name|
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
