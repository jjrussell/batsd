class Job::QueueConversionNotificationsController < Job::SqsReaderController

  def initialize
    super QueueNames::CONVERSION_NOTIFICATIONS
    # Raising on error means the job doesn't process the rest
    @raise_on_error = false
  end

  private

  def on_message(message)
    @reward = Reward.find(message.body, :consistent => true)
    raise "Reward not found: #{message.body}" if @reward.nil?

    begin
      @device = Device.new(:key => @reward.udid)

      device_aliases = [
        {:namespace => 'android_id', :identifier => @device.android_id},
        {:namespace => 'mac_sha1',   :identifier => @device.mac_address && Digest::SHA1.hexdigest(@device.mac_address)},
        {:namespace => 'idfa',       :identifier => @device.idfa}
      ].reject{ |a| a[:identifier].nil?  }

      @publisher_app = App.find_in_cache(@reward.publisher_app_id)

      @notification = NotificationsClient::Notification.new({
        :app_id => @reward.publisher_app_id, 
        :title => I18n.t('queue_conversion_notifications_controller.notification.title', :default => "Reward Notification"),
        :message => I18n.t('queue_conversion_notifications_controller.notification.message', :default => "Your reward from #{@publisher_app.name} is available!"),
        :device_aliases => device_aliases
      })
      @notification.deliver
    rescue NotificationsClient::ValidationException => e
      Rails.logger.error "A notification validation error occurred: #{e.errors.inspect}"
    rescue NotificationsClient::NetworkException => e
      Rails.logger.error "A notification network error occurred: #{e.status_code}"
    end
  end
end
