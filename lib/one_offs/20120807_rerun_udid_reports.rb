class OneOffs
  # devsupport request: the udid_reports job must've failed on these days... need to re-queue them
  def self.rerun_udid_reports
    UdidReports.queue_daily_jobs("2012-06-29")
    UdidReports.queue_daily_jobs("2012-07-09")
    UdidReports.queue_daily_jobs("2012-07-15")
  end
end
