class CloudFront

  ACF = RightAws::AcfInterface.new

  def self.invalidate(id, paths)
    paths = paths.to_a.collect { |path| path.gsub(/^\/?/, "/") }
    begin
      ACF.invalidate('E1MG6JDV6GH0F2', paths, "#{id}.#{Time.now.to_i}")
    rescue Exception => e
      Notifier.alert_new_relic(FailedToInvalidateCloudfront, e.message)
    end
  end

end
