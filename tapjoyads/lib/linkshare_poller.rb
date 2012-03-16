require 'csv'

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
    data = self.download_data
    if data.blank?
      Rails.logger.info(NO_RESULTS_FOUND)
    else
      Rails.logger.info(DOWNLOAD_SUCCESS)
      data.each do |line|
        columns = CSV.parse_line(line)
        if columns[SALES_COLUMN].to_f > 0
          click = Click.find(:key => columns[CLICK_KEY_COLUMN])
          next unless click
          Rails.logger.info("Checking whether or not to reward click #{click.key} from Linkshare...")
          unless click.installed_at?
            message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s}.to_json
            Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
            Rails.logger.info("Linkshare click #{click.key} sent to conversion queue")
          else
            Rails.logger.info("Linkshare click #{click.key} is not rewardable")
          end
        end
      end
    end
  end

  def self.download_data(bdate=nil, edate=nil)
    edate ||= Date.today
    bdate ||= edate - 7.days
    data = self.download_with_retries(bdate, edate)
    data = data.split("\n")
    data.slice!(0)
    data
  end

  def self.download_with_retries(bdate, edate)
    retries = 5
    url = "#{BASE_URL}bdate=#{bdate.to_s(:linkshare)}&edate=#{edate.to_s(:linkshare)}&nid=#{REGION_ID}&reportid=#{SIGNATURE_ACTIVITY_REPORT}&token=#{TAPJOY_SECRET_KEY}"
    begin
      Downloader.get(url, {:timeout => 45})
    rescue
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
