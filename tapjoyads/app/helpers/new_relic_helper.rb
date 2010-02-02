##
# Exposes functionality to easily send alerts to NewRelic.
module NewRelicHelper
  def alert_new_relic(exception, message = nil, request = nil, params = nil)
    begin
      raise exception.new(message)
    rescue Exception => e
      if e.kind_of? EmailWorthyError
        TapjoyMailer.deliver_newrelic_alert(e)
      end
      
      action = params ? params[:action] : nil
      
      NewRelic::Agent.agent.error_collector.notice_error(e, request, action, params)
    end
  end
  
  class MissingRequiredParamsError < RuntimeError; end
  class DuplicateFailedSdbSavesError < RuntimeError; end
  class ParseStoreIdError < RuntimeError; end
  class FailedToWriteToSqsError < RuntimeError; end
  class FailedToDownloadError < RuntimeError; end

  # Any errors that extend this class will result in an email being sent to dev@tapjoy.com.
  class EmailWorthyError < RuntimeError; end
  class ConversionRateTooLowError < EmailWorthyError; end
end