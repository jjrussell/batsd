require 'net/https'
require 'hpricot'
require 'cgi'

class Cron::GetAdNetworkDataController < ApplicationController
  include DownloadContent
  
  before_filter 'authenticate_cron'
  
  def initialize
    @adnetwork_map = {
      '78c4f8c0-4940-4d59-97fe-16bc44981657' => VideoEggSite
    }
  end
  
  def index
    uri = URI.parse("http://tapjoyconnect.com/CronService.asmx/GetAdCampaign?password=taptapcampaign")
    content = download_content(uri, {}, 0)
    
    next_params = []
    
    doc = Hpricot.parse(content)
    ad_network_id = doc.search('//adcampaign/adnetwork').first.inner_text
    campaign_id = doc.search('//adcampaign/adcampaignid').first.inner_text
    app_name = doc.search('//adcampaign/adnetworkid2').first.inner_text
    username = doc.search('//adcampaign/username').first.inner_text
    password = doc.search('//adcampaign/password').first.inner_text
    
    site = @adnetwork_map[ad_network_id].new
    begin
      site.get_data(username, password, app_name)
      report_data(campaign_id, site)
    rescue => e
      logger.info "Failed to get data: #{e}"
      render :text => "FAIL: #{e}"
    else
      render :text => "OK"
    end
  end
  
  private
  
  def report_data(campaign_id, site)
    uri = URI.parse("http://tapjoyconnect.com/CronService.asmx/SubmitAdCampaignData" +
        "?AdCampaignID=#{campaign_id}" +
        "&eCPM=#{site.ecpm}" +
        "&Revenue=#{site.revenue}" +
        "&Impressions=#{site.impressions}" +
        "&FillRate=#{site.fill_rate}" +
        "&Clicks=#{site.clicks}" +
        "&Requests=#{site.requests}" +
        "&CTR=#{site.ctr}" + 
        "&Date=#{site.date}")
    
    response = download_content(uri, {}, 0)
    doc = Hpricot.parse(response)
    response_string = doc.search('//string').first.inner_text
    
    logger.info "Callback response: '#{response_string}'"
  end
  
  class Site
    attr_accessor :ecpm, :revenue, :impressions, :fill_rate, :clicks, :requests, :ctr, :date
  end

  class VideoEggSite < Site
    include DownloadContent

    def get_data(username, password, app_name)
      uri = URI.parse("https://partners.videoegg.com/p/eap/h/1/Reports/partner_report" +
          "?type=csv&form=Package.login.login&doLogin=true" +
          "&input_login_username=#{username}" +
          "&input_login_password=#{password}" +
          "&tab=Site")

      csv = download_content(uri, {}, 0)

      get_next_line = false
      csv.each do |line|
        items = line.split(',')
        if get_next_line
          @date, @impressions, @ctr, @revenue, @ecpm = items
          @ctr = @ctr.gsub(/(\%|\$|\s)/, '')
          @revenue = @revenue.gsub(/(\%|\$|\s)/, '')
          @ecpm = @ecpm.gsub(/(\%|\$|\s)/, '')
          break
        end
        if items[0] == app_name
          get_next_line = true
        end
      end

      unless get_next_line
        raise "Error accessing data"
      end
    end
  end
end
