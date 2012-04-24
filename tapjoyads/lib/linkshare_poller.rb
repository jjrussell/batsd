require 'csv'
require 'open-uri'

class LinksharePoller

  TAPJOY_SECRET_KEY         = "d2ad5373a754a1b6a80b925f9793ebe258a42f033a1a14807169d0753843e7c8"

  BASE_URL                  = "https://reportws.linksynergy.com/downloadreport.php?"

  ERROR_COULD_NOT_CONNECT   = "Error reaching Linkshare API server."
  NO_RESULTS_FOUND          = "Linkshare query yielded no results."
  DOWNLOAD_SUCCESS          = "Successfully downloaded results from Linkshare."

  SIGNATURE_ACTIVITY_REPORT = 11
  REGION_ID                 = 1
  CLICK_KEY_COLUMN          = 0
  SALES_COLUMN              = 4

  def self.poll
    data_table = self.download_with_retries
    if data_table.blank?
      Rails.logger.info(NO_RESULTS_FOUND)
    else
      Rails.logger.info(DOWNLOAD_SUCCESS)
      self.process_clicks(data_table)
    end
  end

  def self.process_clicks(raw_table)
    now = Time.zone.now.to_f.to_s
    CSV.parse(raw_table) do |row|
      next if row.length != 6 || row[SALES_COLUMN].to_f <= 0
      click = Click.find(row[CLICK_KEY_COLUMN])
      next unless click && !click.installed_at?
      message = { :click_key => click.key, :install_timestamp => now }.to_json
      Rails.logger.info("Sending Linkshare click #{click.key} to conversion queue.")
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end
  end

  def self.download_with_retries(bdate=nil, edate=nil)
    edate ||= Date.today
    bdate ||= edate - 7.days
    retries = 5
    url = "#{BASE_URL}bdate=#{bdate.to_s(:linkshare)}&edate=#{edate.to_s(:linkshare)}&nid=#{REGION_ID}&reportid=#{SIGNATURE_ACTIVITY_REPORT}&token=#{TAPJOY_SECRET_KEY}"
    Rails.logger.info("Attempting Linkshare data download via #{url}.")
    begin
      open(url).read
    rescue Exception => e
      Rails.logger.info("Linkshare data download failed. Will retry #{retries} more times.")
      if retries > 0
        delay ||= 0.1
        retries -= 1
        sleep(delay)
        delay *= 2
        retry
      else
        raise e
      end
    end
  end

end
