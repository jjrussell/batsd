class MissingRequiredParamsError < RuntimeError; end
class ParseStoreIdError < RuntimeError; end
class FailedToWriteToSqsError < RuntimeError; end
class FailedToDownloadError < RuntimeError; end
class AppStatsVerifyError < RuntimeError; end
class GetStoreInfoError < RuntimeError; end
class InvalidPlaydomUserId < RuntimeError; end
class TooManyUdidsForPublisherUserId < RuntimeError; end

# Any errors that extend this class will result in an email being sent to dev@tapjoy.com.
class EmailWorthyError < RuntimeError
  def deliver_email
    TapjoyMailer.deliver_newrelic_alert(self)
  end
end
class BalancesMismatch < EmailWorthyError; end
class ConversionRateTooLowError < EmailWorthyError
  def deliver_email
    TapjoyMailer.deliver_low_conversion_rate_warning(self)
  end
end



class Notifier
  
  def self.alert_new_relic(exception, message = nil, request = nil, params = nil)
    begin
      raise exception.new(message)
    rescue Exception => e
      action = params ? params[:action] : nil
      
      NewRelic::Agent.agent.error_collector.notice_error(e, request, action, params)
      
      if e.kind_of?(EmailWorthyError)
        e.deliver_email
      end
    end
  end
  
end
