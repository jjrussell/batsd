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

      @notification = NotificationsClient::Notification.new({
        :app_id => @reward.publisher_app_id, 
        :title => I18n.t('queue_conversion_notifications_controller.notification.title', :default => "Reward Notification"),
        :message => message_text,
        :device_aliases => device_aliases
      })
      @notification.deliver
    rescue NotificationsClient::ValidationException => e
      Rails.logger.error "A notification validation error occurred: #{e.errors.inspect}"
    rescue NotificationsClient::NetworkException => e
      Rails.logger.error "A notification network error occurred: #{e.status_code}"
    end
  end

private
  def message_text
    #add custom message text where appropriate 
    case @reward.offer.item_type
    when "App"
      #PPI
      i18n_message("You earned #{currency.name} by downloading #{advertiser_app.name}")
    else
      i18n_message("Your #{currency.name} in #{publisher_app.name} is available!")
    end
  end

  def i18n_message(s)
    I18n.t('queue_conversion_notifications_controller.notification.message', :default => s)
  end

  def publisher_app
    App.find_in_cache(@reward.publisher_app_id)
  end

  def advertiser_app
    App.find_in_cache(@reward.advertiser_app_id)
  end

  def currency
    Currency.find_in_cache(@reward.currency_id)
  end
end
