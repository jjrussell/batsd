class AdminDeviceLastRun
  # some magic for controllers that want to track web request data
  # for `AdminDevice`s.
  module ControllerExtensions
    extend ActiveSupport::Concern

    module InstanceMethods
      def should_track_device?
        # The easiest check, and sets @device
        @device ||= find_or_create_device(params[:temporary_device_id].present?)
        return true if @device.last_run_time_tester?

        # Check for partner test device
        begin
          Currency.find_all_in_cache_by_app_id(params[:app_id]).
            collect(&:get_test_device_ids).inject(:+).
            any? { |udid| udid == params[:udid] }
        rescue
          # the map reduce above could result in nil.any?, so rescue with false
          false
        end
      end

      def track_admin_device
        return if get_device_key.blank?
        @device ||= find_or_create_device(params[:temporary_device_id].present?)

        if should_track_device?
          @device.changed? and @device.save
          AdminDeviceLastRun.add(
            :udid => params[:udid],
            :tapjoy_device_id => get_device_key,
            :app_id => params[:app_id],
            # some controllers like to set their own @web_request
            # if this isn't one of them, use ApplicationController's version
            :web_request => @web_request || generate_web_request
          )
        end
      end
    end

    module ClassMethods
      def tracks_admin_devices(*args_for_after_filter)
        after_filter(:track_admin_device, *args_for_after_filter)
      end
    end
  end
end
