require 'csv'

class LinksharePoller

  TAPJOY_SECRET_KEY         = "d2ad5373a754a1b6a80b925f9793ebe258a42f033a1a14807169d0753843e7c8"

  BASE_URL                  = "https://reportws.linksynergy.com/downloadreport.php?"

  ERROR_COULD_NOT_CONNECT   = "Error reaching Linkshare API server."
  NO_RESULTS_FOUND          = "Query yielded no results."
  DOWNLOAD_SUCCESS          = "Successfully downloaded results from Linkshare."
  CLICK_NOT_REWARDABLE      = "Click is not rewardable."

  SIGNATURE_ACTIVITY_REPORT = 11
  CLICK_KEY_COLUMN          = 0
  SALES_COLUMN              = 4

  def self.test
    january_thirtieth = Date.civil(2012,1,30)
    self.poll(january_thirtieth)   # should attempt to resolve one click with key 511865e0-f0d9-4151-94c4-2047081602f8
    self.poll(january_thirtieth + 1.week)   # should handle no results properly
  end

  def self.poll(date=nil)
    edate = date || Date.today
    bdate = edate - 1.day
    options = {
      :edate    => edate.to_s.tr('-', ''),
      :bdate    => bdate.to_s.tr('-', ''),
      :token    => TAPJOY_SECRET_KEY,
      :nid      => 1,
      :reportid => 11,
    }
    data = self.download_data(options)
    Rails.logger.info NO_RESULTS_FOUND and return if data.blank?
    Rails.logger.info DOWNLOAD_SUCCESS
    data.each do |line|
      columns = CSV.parse_line(line)
      if columns[SALES_COLUMN].to_f > 0
        click = Click.new(:key => columns[CLICK_KEY_COLUMN])
        Rails.logger.info "Attempting to resolve click #{click.key}"
        if click.rewardable?
          message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
          Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
          Rails.logger.info "Click #{click.key} sent to conversion queue"
        else
          Rails.logger.info CLICK_NOT_REWARDABLE
        end
      end
    end
  end

  private

  def self.download_data(options)
    data = self.download_with_retries(BASE_URL + options.to_query)
    data = data.split("\n")
    data.slice!(0)
    data
  end

  def self.download_with_retries(url)
    retries = 5
    begin
      Downloader.get(url, {:timeout => 4})
    rescue Exception => e
      Rails.logger.info("Linkshare data download failed. Will retry #{retries} more times. #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
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
