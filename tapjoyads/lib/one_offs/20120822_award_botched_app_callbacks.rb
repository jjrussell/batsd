require 'csv'

# devsupport request: A particular advertiser botched their server-to-server integration,
#                     causing several of their clicks to not be rewarded or tracked by our
#                     system.  The advertiser provided a CSV of all clicks that occurred
#                     before they fixed their integration.  Since some of the clicks in the
#                     list are more than two days old, we have to resolve the clicks
#                     manually rather than simply re-issuing the API calls.

class OneOffs
  def self.award_botched_app_callbacks
    s3_filename = 'hotel-tonight-pings.csv'
    file = Tempfile.new(s3_filename)

    puts "Downloading #{s3_filename}..."
    file.write(S3.bucket(BucketNames::SUPPORT_REQUESTS).objects[s3_filename].read)
    file.rewind

    puts "Counting rows in CSV..."
    row_count = 0
    CSV.foreach(file.path) { row_count += 1 }

    puts "Awarding clicks..."
    bar = ProgressBar.new(row_count, :percentage, :bar, :eta)
    award_count = 0

    CSV.foreach(file.path) do |created, publisher_name, site_name, site_event_name, url, http_result, publisher_id, site_id, site_event_id|
      params = CGI::parse(URI.parse(url).query)

      # Sanitize goofy CGI parser format and correct app_id
      params.each { |key,value| params[key] = value.first }
      params.delete_if { |key,value| value.blank? }
      params["app_id"] = "c8196876-6458-4fab-bed6-c9306fe35b05" if params["app_id"] != "c8196876-6458-4fab-bed6-c9306fe35b05"

      ## NOTE: None of the API calls in this CSV contain UDIDs.  When a device is created with a MAC address only, the
      ##       CreateDeviceIdentifiers job assigns it a generated UDID.  Any subsequent clicks are therefore keyed using
      ##       the generated UDID rather than the MAC.  Thus, looking up the key using the "udid" and "mac" params doesn't
      ##       work in this case.  Instead, we need get the device record, look up its generated UDID, then look for the
      ##       click with that generated UDID.  We should also count the number of awards we actually give.

      # Find click in SimpleDB
      click = nil

      if params['udid'].present?
        click = Click.new(:key => "#{params['udid']}.#{params['app_id']}", :consistent => true)
      elsif params['mac_address'].present?
        mac_address = params['mac_address'].downcase.gsub(/:/,"")
        device_identifier = DeviceIdentifier.new(:key => mac_address)
        raise "Could not identify device with MAC address: #{mac_address}" if device_identifier.new_record?

        click = Click.new(:key => "#{device_identifier.udid}.#{params['app_id']}", :consistent => true)
        if click.new_record? && mac_address != params['udid']
          click = Click.new(:key => "#{mac_address}.#{params['app_id']}", :consistent => true)
        end
      else
        raise "No device identifier provided"
      end

      # Force resolve if the click existed previously
      unless click.new_record?
        click.resolve!
        award_count += 1
      end

      bar.increment!
    end

    puts "Awards issued: #{award_count}"
  end
end
