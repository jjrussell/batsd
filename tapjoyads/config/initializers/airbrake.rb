Airbrake.configure do |config|
  config.api_key = '54ad56ce4f8a75e5b413ab3e325d88f9'
  config.ignore_by_filter do |exception_data|
    if exception_data[:error_class] == 'RightAws::AwsError'
      true if exception_data[:error_message] =~ /^(ServiceUnavailable|SignatureDoesNotMatch)/
    end
  end
end
