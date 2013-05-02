require 'sqs'
require 'queue_names'
require 'stats_cache'

class ConnectController < ApplicationController
  include AdminDeviceLastRun::ControllerExtensions

  tracks_admin_devices # :only => [:index]
  before_filter :reject_banned_udids

  # Order is important.
  PRIORITIZED_DEVICE_IDENTIFIER_TO_NAME_MAP = {
    :advertising_id => "Advertising ID",
    :open_udid      => "OpenUDID",
    :android_id     => "Android ID",
    :serial_id      => "Serial ID",
    :mac_address    => "MAC Address",
    :udid           => "UDID"           # Not necessarily an actual UDID
  }


  # Handles calls from the advertiser SDK on startup. This call is the mechanism
  # by which Tapjoy identifies whether an app has been installed on a given
  # device.
  #
  # These endpoints are also called in custom "server-to-server" implementations
  # of the Tapjoy platform. Because of this, badly-behaved implementations may
  # not supply the same typical values as the somewhat-standardized advertiser
  # SDKs supply.
  #
  # == Params
  #
  # +:udid+                 - IMEI or MEID for Android. Serial for wifi-only devices.  UUID for iOS. MAC for some badly-behaved server-to-server implementations.
  # +:device_name+          - The device name or model. Ex: "DroidX", "Droid", "iPhone1,1", "iPod 1,1", etc.
  # +:device_type+          - Device type. Typically 'android', 'iphone', 'ipod', etc.
  # +:os_version+           - Version of Android or iOS running.
  # +:country_code+         - The "Alpha-2" code for the country from which the request was made. See: http://en.wikipedia.org/wiki/ISO_3166-1
  # +:language_code+        - Language code
  # +:app_id+               - The Tapjoy ID for the app making the connect call
  # +:app_version+          - The advertiser's version number for their app
  # +:library_version+      - The version number of the Tapjoy SDK making the call
  # +:publisher_user_id+    - The publisher-specified User ID for this device/account.  By default, this is the “udid” if using Tapjoy Managed Currency.  Otherwise this is set by the publisher.
  # +:carrier_name+         - The carrier name for the device making the call
  # +:carrier_country_code+ - The carrier-supplied Country Code (ISO)
  # +:mobile_country_code+  - The carrier-supplied Mobile Country Code (MCC)
  # +:mobile_network_code+  - The carrier-supplied Mobile Network Code (MNC)
  # +:connection_type+      - The device's connection type. 'mobile' or 'WIFI'
  # +:platform+             - Software platform running on the device (ex: "android")
  # +:timestamp+            - The time at which the call was made. Seconds since January 1st, 1970
  # +:verifier+             - SHA256 hash computed by taking the appID, UDID, timestamp, and app secret key separated by colons - (app_id + ":" + udid + ":" + timestamp + ":" + secret_key)
  # +:sdk_type+             - SDK type. 'connect' (advertiser SDK), 'offers' (publisher SDK) or 'virtual_goods' (deprecated)
  # +:plugin+               - Plugin type (ex: unity, phonegap, marmalade, adobeair, native)

  # === iOS SPECIFIC
  # +:lad+                  - Jailbreak status of the device. 0 for non-jailbroken devices, else 1
  # +:mac_address+          - MAC address of the device, with colons removed
  # +:sha1_mac_address+     - SHA1 hash of the MAC address, colon separated
  # +:open_udid+            - The OpenUDID
  # +:open_udid_count+      - The Open UDID slot count
  # +:advertising_id+       - The IDFA of the device

  # === ANDROID SPECIFIC
  # +:android_id+           - The ANDROID_ID of the device
  # +:device_manufacturer+  - The manufacturer of the device
  # +:screen_density+       - The device's screen density
  # +:screen_layout_size+   - The device's screen layout size
  # +:serial_id+            - The hardware serial of the device
  # +:sha1_mac_address+     - SHA1 hash of the MAC address, uppercase, colon separated

  # === WP7 SPECIFIC
  # +:device_manufacturer+  - The manufacturer of the device
  def index
    lookup_device_id(true)
    required_param = [:app_id]
    required_param << :udid unless params[:identifiers_provided]

    return unless verify_params(required_param)
    return unless params[:udid].present?

    current_device #sets @device instance variable (application controller)
    fix_lookedup_udid
    click     = nil
    path_list = []

    unless current_device.has_app?(params[:app_id]) && current_device.is_temporary
      available_device_ids_for_click_matching.each do |device_id|
        click = click_for_device(device_id)
        break unless click.new_record?
      end

      if click.new_record? && params[:mac_address].present? && params[:mac_address] != params[:udid]
        click = Click.new(:key => "#{params[:mac_address]}.#{params[:app_id]}", :consistent => params[:consistent])
      end

      record_conversion(click) if click.rewardable?
    end

    # ivar for the benefit of tracks_admin_devices
    @web_request = WebRequest.new
    @web_request.put_values('connect', params, ip_address, geoip_data, request.headers['User-Agent'])
    @web_request.raw_url = request.url

    if click
      @web_request.click_id       =  click.id
      @web_request.click_offer_id =  click.offer_id
      path_list                   << 'conversion_user'
    end

    update_web_request_store_name(@web_request, params[:app_id])

    path_list += @device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      @web_request.path = path
    end

    begin
      @web_request.save
    rescue JSON::GeneratorError => e
      @web_request.attributes.ensure_utf8_encoding!
      @web_request.save # will re-raise the same thing if fix doesn't work
    end

    if sdkless_supported?
      @sdkless_clicks = @device.sdkless_clicks
    end
  end

  private

  def record_conversion(click)
    if click && click.rewardable?
      message = {
        :click_key         => click.key,
        :device_identifier => advertiser_supplied_device_identifier,
        :install_timestamp => Time.zone.now.to_f.to_s
      }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end
  end

  def fix_lookedup_udid
    if current_device.advertising_id_device?
      params[:lookedup_udid] = nil unless params[:lookedup_udid].udid? && Device.find(params[:lookedup_udid])
      params[:lookedup_udid] = mac_address_device_id unless params[:lookedup_udid].present?
    end
  end

  def mac_address_device_id
    return nil unless params[:mac_address]
    device_id = DeviceIdentifier.find(params[:mac_address]).try(:udid)
    device_id.udid? ? device_id : nil
  end

  def available_device_ids_for_click_matching
    return @click_device_ids if @click_device_ids

    @click_device_ids = [ current_device.id,
                          params[:udid],
                          current_device.udid,
                          current_device.advertising_id,
                          current_device.mac_address,
                          params[:mac_address],
                          params[:lookedup_udid]]
    @click_device_ids.uniq!.compact!
    @click_device_ids
  end

  def click_for_device(device_id_for_click)
    Click.new(:key => "#{device_id_for_click}.#{params[:app_id]}", :consistent => params[:consistent])
  end

  # For reporting purposes, we are to record the advertiser-supplied unique
  # identifier(s) for the device that are least privacy-invasive.
  def advertiser_supplied_device_identifier
    PRIORITIZED_DEVICE_IDENTIFIER_TO_NAME_MAP.each do |id, name|
      return {:id => params[id], :type => name} if params[id].present?
    end
    return {}
  end
end
