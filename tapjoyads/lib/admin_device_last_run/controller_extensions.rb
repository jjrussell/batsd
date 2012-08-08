class AdminDeviceLastRun
  # some magic for controllers that want to track web request data
  # for `AdminDevice`s.  
  module ControllerExtensions
    def self.included(base)
      class << base
        include ClassMethods
      end
    end

    # The after filter itself
    def track_admin_device
      @device ||= Device.new(
        :key => params[:udid],
        :is_temporary => params[:udid_is_temporary].present?
      )

      if @device.last_run_time_tester?
        __web_request = @web_request || generate_web_request
        AdminDeviceLastRun.set(
          :udid => params[:udid],
          :app_id => params[:app_id],
          # some controllers like to set their own @web_request
          # if this isn't one of them, use ApplicationController's version
          :web_request => __web_request
        )
      end
    end

    module ClassMethods
      # Railsish facade
      def tracks_admin_devices(*args_for_after_filter)
        after_filter(:track_admin_device, *args_for_after_filter)
      end
    end
  end
end
