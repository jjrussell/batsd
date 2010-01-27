##
# Exposes functionality to easily send alerts to NewRelic.
module NewRelicHelper
  def alert_new_relic(exception, message = nil, request = nil, params = nil)
    begin
      raise exception.new(message)
    rescue Exception => e
      action = params ? params[:action] : nil
      
      NewRelic::Agent.agent.error_collector.notice_error(e, request, action, params)
    end
  end
  
  class MissingRequiredParamsError < RuntimeError
  end
  
  class DuplicateFailedSdbSavesError < RuntimeError
  end
  
  class ConversionRateTooLowError < RuntimeError
  end
  
  class FailedToDownloadError < RuntimeError
  end
  
  class ParseStoreIdError < RuntimeError
  end
  
end