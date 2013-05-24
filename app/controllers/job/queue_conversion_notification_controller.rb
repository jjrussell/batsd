class Job::QueueConversionNotificationsController < Job::SqsReaderController
include ActionView::Helpers::TextHelper

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

      device_aliases = [{
        :device_key => @device.key,
        :android_id => @device.android_id,
        :mac_sha1   => @device.mac_address && Digest::SHA1.hexdigest(Device.formatted_mac_address(@device.mac_address)),
        :idfa       => @device.advertising_id
      }.reject{ |k,v| v.nil? }]

      @notification = NotificationsClient::Notification.new({
        :app_id => @reward.publisher_app_id,
        :app_secret_key => publisher_app.secret_key,
        :title => I18n.t('queue_conversion_notifications_controller.notification.title', :default => "Reward Notification"),
        :message => message_text,
        :throttle_key => 'tjofferconversion',
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
      i18n_message("You earned #{@reward.currency_reward} #{currency.name} by downloading #{advertiser_app.name}")
    else
      i18n_message("Your #{@reward.currency_reward} #{currency.name} in #{publisher_app.name} are available!")
    end
  end

  def i18n_message(s)
    I18n.t('queue_conversion_notifications_controller.notification.message', :default => s)
  end

  def publisher_app
    @publisher_app ||= App.find_in_cache(@reward.publisher_app_id)
  end

  def advertiser_app
    @advertiser_app ||= App.find_in_cache(@reward.advertiser_app_id)
  end

  def currency
    @currency ||= Currency.find_in_cache(@reward.currency_id)
  end
end
