#!/usr/bin/env ruby

require 'logger'
require 'net/https'
require 'rubygems'
require 'hpricot'
require 'cgi'

$logger = Logger.new("get_ad_network_data.log", 'daily')

module DownloadContent
  def download_content(uri, *headers)
    start_time = Time.now
    $logger.info "Downloading #{uri.to_s}"
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      content = http.get(uri.request_uri, *headers)
    end
    content = res.body
    $logger.info "Downloaded complete (#{Time.now - start_time}s)"
  
    return content
  end
end

class GetAdNetworkDataService

  include DownloadContent
  #include XML

  def initialize
    @service_pass = 'taptapcampaign'
    
    @adnetwork_map = {
      '78c4f8c0-4940-4d59-97fe-16bc44981657' => VideoEggSite
    }
  end

  def get_ad_data
    $logger.info "START"
    uri = URI.parse("http://tapjoyconnect.com/CronService.asmx/GetAdCampaign?password=#{@service_pass}")
    content = download_content(uri)
    #doc =  XML::Parser.string(content).parse
    doc = Hpricot.parse(content)
  
    ad_network_id = doc.search('//adcampaign/adnetwork').first.inner_text
    campaign_id = doc.search('//adcampaign/adcampaignid').first.inner_text
    app_name = doc.search('//adcampaign/adnetworkid2').first.inner_text
    username = doc.search('//adcampaign/username').first.inner_text
    password = doc.search('//adcampaign/password').first.inner_text
    
    site = @adnetwork_map[ad_network_id].new
    begin
      site.get_data(username, password, app_name)
      callback(campaign_id, site)
    rescue => e
      $logger.info "Aborted: #{e}"
    end
    
    $logger.info "END"
  end
  
  def callback(campaign_id, site)
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
    
    response = download_content(uri)
    doc = Hpricot.parse(response)
    response_string = doc.search('//string').first.inner_text
    
    $logger.info "Callback response: '#{response_string}'"
  end
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
        
    $logger.info "Downloading (with curl) #{uri.to_s}"
    csv = `curl -s '#{uri.to_s}'`
    
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

loop {
  GetAdNetworkDataService.new.get_ad_data
}
