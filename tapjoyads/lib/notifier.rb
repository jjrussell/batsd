class MissingRequiredParamsError < RuntimeError; end
class ParseStoreIdError < RuntimeError; end
class FailedToWriteToSqsError < RuntimeError; end
class FailedToDownloadError < RuntimeError; end
class AppStatsVerifyError < RuntimeError; end
class GetStoreInfoError < RuntimeError; end
class InvalidPlaydomUserId < RuntimeError; end
class TooManyUdidsForPublisherUserId < RuntimeError; end
class BadWebRequestDomain < RuntimeError; end
class AppDataFetchError < RuntimeError; end
class GenericOfferCallbackError < RuntimeError; end
class InvalidAppIdForDevices < RuntimeError; end
class DeviceCountryChanged < RuntimeError; end
class DeviceNoLongerJailbroken < RuntimeError; end
class JailbrokenInstall < RuntimeError; end
class FailedToInvalidateCloudfront < RuntimeError; end
class RecordNotFoundError < RuntimeError; end
class AppStoreSearchFailed < RuntimeError; end

# Any errors that extend this class will result in an email being sent to dev@tapjoy.com.
class EmailWorthyError < RuntimeError
  def deliver_email(params={})
    TapjoyMailer.deliver_newrelic_alert(self)
  end
end
class BalancesMismatch < EmailWorthyError; end
class ConversionRateTooLowError < EmailWorthyError
  def deliver_email(params={})
    TapjoyMailer.deliver_low_conversion_rate_warning(self, params)
  end
end



class Notifier
  
  def self.alert_new_relic(exception, message = nil, request = nil, params = nil)
    begin
      raise exception.new(message)
    rescue Exception => e
      action_path = params.present? ? "#{params[:controller]}/#{params[:action]}" : nil
      
      NewRelic::Agent.agent.error_collector.notice_error(e, request, action_path, params)
      
      if e.kind_of?(EmailWorthyError)
        e.deliver_email(params)
      end
    end
  end
  
end
