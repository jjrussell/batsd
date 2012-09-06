class AdminDeviceLastRun
  # some magic for controllers that want to track web request data
  # for `AdminDevice`s.
  module ControllerExtensions
    extend ActiveSupport::Concern

    module InstanceMethods
      def should_track_device?
        # The easiest check
        return true if AdminDevice.where(:udid => params[:udid]).any?

        # The second easiest check, and sets @device
        @device ||= Device.new(
          :key => params[:udid],
          :is_temporary => params[:udid_is_temporary].present?
        )
        return true if @device.last_run_time_tester?

        # The slowest check; for partner test devices
        Currency.where(:app_id => params[:app_id]).
          collect(&:get_test_device_ids).inject(:+).
          any? { |udid| udid == params[:udid] }
      end

      def track_admin_device
        @device ||= Device.new(
          :key => params[:udid],
          :is_temporary => params[:udid_is_temporary].present?
        )

        if should_track_device?
          @device.changed? and @device.save
          AdminDeviceLastRun.add(
            :udid => params[:udid],
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
