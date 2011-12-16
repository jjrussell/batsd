class FailedToWriteToSqsError < RuntimeError; end
class FailedToDownloadError < RuntimeError; end
class AppStatsVerifyError < RuntimeError; end
class GetStoreInfoError < RuntimeError; end
class AppDataFetchError < RuntimeError; end
class AppReviewEmptyError < RuntimeError; end
class GenericOfferCallbackError < RuntimeError; end
class DeviceCountryChanged < RuntimeError; end
class JailbrokenInstall < RuntimeError; end
class FailedToInvalidateCloudfront < RuntimeError; end
class SdbObjectNotInS3 < RuntimeError; end
class SkippedSendCurrency < RuntimeError; end
class AndroidRank404 < RuntimeError; end
class EmailVerificationFailure < RuntimeError; end

# Any errors that extend this class will result in an email being sent to dev@tapjoy.com.
class EmailWorthyError < RuntimeError
  def deliver_email(params={})
    TapjoyMailer.deliver_newrelic_alert(self)
  end
end
class BalancesMismatch < EmailWorthyError; end
class UnverifiedStatsError < EmailWorthyError; end
class AppStoreSearchFailed < EmailWorthyError; end
class VerticaDataError < EmailWorthyError; end
class AndroidMarketChanged < EmailWorthyError; end
class PapayaAPIError < EmailWorthyError; end

class Notifier

  def self.alert_new_relic(exception, message = nil, request = nil, params = nil)
    begin
      raise exception.new(message)
    rescue Exception => e
      options = {}
      if request.present?
        options[:uri] = request.path
        options[:referer] = request.referer
      end
      if params.present?
        options[:request_params] = params
      end
      NewRelic::Agent.agent.error_collector.notice_error(e, options)

      if e.kind_of?(EmailWorthyError)
        e.deliver_email(params)
      end
    end
  end

end
