require 'csv'

class LinksharePoller

  TAPJOY_SECRET_KEY         = "d2ad5373a754a1b6a80b925f9793ebe258a42f033a1a14807169d0753843e7c8"

  ERROR_COULD_NOT_CONNECT   = "Error reaching Linkshare API server."
  NO_RESULTS_FOUND          = "Query yielded no results."
  DOWNLOAD_SUCCESS          = "Successfully downloaded results from Linkshare."
  CLICK_NOT_REWARDABLE      = "Click is not rewardable."

  SIGNATURE_ACTIVITY_REPORT = 11
  CLICK_KEY_COLUMN          = 0
  SALES_COLUMN              = 4


   def self.test
    self.poll("20120130")   # should attempt to resolve one click with key 511865e0-f0d9-4151-94c4-2047081602f8
    self.poll("20120131")   # should handle no results properly
  end

  def self.poll(date=nil)
    today = Date.today
    yesterday = today - 1.day
    options = {
      :bdate    => yesterday.to_s.tr('-', ''),
      :edate    => today.to_s.tr('-', ''),
      :token    => TAPJOY_SECRET_KEY,
      :nid      => 1,
      :reportid => 11,
    }

    data = self.download_data(options)
    return if data.blank?
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
    begin
      url = "https://reportws.linksynergy.com/downloadreport.php?"
      options.to_a.each do |keyval_pair|
        url << "#{keyval_pair.join('=')}&"
      end
      url.chop!
      puts "Final URL: #{url}"
      raw_data = Downloader.get(url, {:timeout => 10}).chomp
      data = raw_data.split("\n")
      data.slice!(0)
      Rails.logger.info NO_RESULTS_FOUND if data.blank?
    rescue
      TapjoyMailer.deliver_linkshare_alert(ERROR_COULD_NOT_CONNECT, url, options)
    end
    data
  end


end
