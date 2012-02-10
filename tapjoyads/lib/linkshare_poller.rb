require 'csv'

class LinksharePoller

  ERROR_UNREACHABLE     = "Linkshare API Server Unreachable"
  ERROR_EMPTY_RESPONSE  = "Empty Response"
  ERROR_API_CHANGED     = "API Response Format Changed"

  NO_RESULTS_FOUND = "No Results Found"

  SIGNATURE_ACTIVITY_HEADER = "Member ID,Advertiser ID,Advertiser Name,Clicks,Sales,Commissions"
  MINIMUM_BYTES_IN_RESPONSE = SIGNATURE_ACTIVITY_HEADER.length + 1

  REPORT_ID = {
    :sales                    => 4,
    :revenue                  => 5,
    :link_type                => 6,
    :individual_item          => 7,
    :product_success          => 8,
    :program_level            => 9,
    :non_commisionable_sales  => 10,
    :signature_activity       => 11,
    :signature_order          => 12,
    :media_optimization       => 14,
  }

  SIGNATURE_ACTIVITY_FORMAT = {
    :click_key        => 0,
    :advertiser_id    => 1,
    :advertiser_name  => 2,
    :clicks           => 3,
    :sales            => 4,
    :commissions      => 5,
  }

  NETWORK_ID = {
    :US => 1,
    :UK => 3,
    :CA => 5,
  }

  def self.test
    # stupid test that should grab a large table with 1 valid click in it
    self.poll("20120130")
  end

  def self.poll(date=nil, newtork_id=nil, report_id=nil)
    date = Date.today.to_s.tr('-', '') if date.nil?
    network_id = NETWORK_ID[:US] if network_id.nil?
    report_id = REPORT_ID[:signature_activity] if report_id.nil?
    url = "https://reportws.linksynergy.com/downloadreport.php?bdate=#{date}&edate=#{date}&token=#{TAPJOY_SECRET_TOKEN}&nid=#{network_id}&reportid=#{report_id}"

    csv_table = Downloader.get(url) rescue TapjoyMailer.deliver_linkshare_alert(ERROR_UNREACHABLE, date, date, report_id, url, network_id) and return
    csv_table.chomp!
    TapjoyMailer.deliver_linkshare_alert(ERROR_EMPTY_RESPONSE, date, date, report_id, url, network_id) and return if csv_table.blank?
    return if csv_table.include?(NO_RESULTS_FOUND)
    TapjoyMailer.deliver_linkshare_alert(csv_table, date, date, report_id, url, network_id) and return if csv_table.length < MINIMUM_BYTES_IN_RESPONSE
    lines = csv_table.split("\n")
    TapjoyMailer.deliver_linkshare_alert(ERROR_API_CHANGED, date, date, report_id, url, network_id) and return unless lines[0].include?(SIGNATURE_ACTIVITY_HEADER)
    lines.slice! 0
    lines.each do |line|
      columns = CSV.parse_line(line)
      if columns[SIGNATURE_ACTIVITY_FORMAT[:sales]].to_f > 0
        click = Click.new(:key => columns[SIGNATURE_ACTIVITY_FORMAT[:click_key]])
        click.resolve! if click.rewardable?
      end
    end
  end

  private

  TAPJOY_SECRET_TOKEN = "d2ad5373a754a1b6a80b925f9793ebe258a42f033a1a14807169d0753843e7c8"


end
