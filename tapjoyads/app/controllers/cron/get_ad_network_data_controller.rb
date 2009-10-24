require 'net/https'
require 'hpricot'
require 'cgi'
require 'patron'
require 'json'

class Cron::GetAdNetworkDataController < ApplicationController
  include DownloadContent
  
  before_filter 'authenticate_cron'
  
  def initialize
    @adnetwork_map = {
      '78c4f8c0-4940-4d59-97fe-16bc44981657' => VideoEggSite,
      'f2eb272c-1783-4589-99a0-667e1a45ac51' => MillennialSite
    }
  end
  
  def index
    uri = URI.parse("http://tapjoyconnect.com/CronService.asmx/GetAdCampaign?password=taptapcampaign")
    content = download_content(uri, {}, 30)
    
    next_params = []
    
    doc = Hpricot.parse(content)
    ad_network_id = doc.search('//adcampaign/adnetwork').first.inner_text
    campaign_id = doc.search('//adcampaign/adcampaignid').first.inner_text
    ad_network_id1 = doc.search('//adcampaign/adnetworkid1').first.inner_text
    ad_network_id2 = doc.search('//adcampaign/adnetworkid2').first.inner_text
    ad_network_id3 = doc.search('//adcampaign/adnetworkid3').first.inner_text
    username = doc.search('//adcampaign/username').first.inner_text
    password = doc.search('//adcampaign/password').first.inner_text
    
    begin
      site = @adnetwork_map[ad_network_id].new
      site.get_data(username, password, ad_network_id1, ad_network_id2, ad_network_id3)
      report_data(campaign_id, site.today_data)
      report_data(campaign_id, site.yesterday_data)
    rescue => e
      logger.info "Failed to get data: #{e}"
      render :text => "FAIL: #{e}"
    else
      render :text => "OK"
    end
  end
  
  private
  
  def report_data(campaign_id, data)
    uri = URI.parse("http://tapjoyconnect.com/CronService.asmx/SubmitAdCampaignData" +
        "?AdCampaignID=#{campaign_id.to_s}" +
        "&eCPM=#{data.ecpm.to_s}" +
        "&Revenue=#{data.revenue.to_s}" +
        "&Impressions=#{data.impressions.to_s}" +
        "&FillRate=#{data.fill_rate.to_s}" +
        "&Clicks=#{data.clicks.to_s}" +
        "&Requests=#{data.requests.to_s}" +
        "&CTR=#{data.ctr.to_s}" + 
        "&Date=#{data.date.to_s}")
    
    response = download_content(uri, {}, 30)
    doc = Hpricot.parse(response)
    response_string = doc.search('//string').first.inner_text
    
    logger.info "Callback response: '#{response_string}'"
  end
  
  class Data
    attr_accessor :ecpm, :revenue, :impressions, :fill_rate, :clicks, :requests, :ctr, :date
  end

  class Site
    include DownloadContent
    attr_accessor :today_data, :yesterday_data
  end

  class MillennialSite < Site
    def get_data(username, password, ad_network_id1, site_id, ad_network_id3)
      sess = Patron::Session.new
      sess.handle_cookies
      sess.base_url = 'clients.millennialmedia.com'
      #sess.get('/')
      sess.post('/', "username=#{username}&password=#{password}")
      
      response = sess.get("/publisher/publisher-statistics-default.php5?" +
          "siteid=#{site_id}&timecheck=DX7&drawer=statistics")
      content = response.body

      json_string = content.match(/var rootReportObj = (\{.*\})\;/)[1]
      json = JSON.parse(json_string)
      
      values = []
      
      puts json_string
      
      json.each do |key, value|
        values.push(value)
      end
      
      values.sort! do |a, b|
        Time.parse(b['name']) <=> Time.parse(a['name'])
      end
      
      @today_data = get_data_from_json(values[0])
      @yesterday_data = get_data_from_json(values[1])
    end
    
    def get_data_from_json(json)
      data = Data.new
      
      data.revenue = json['revenue']
      data.impressions =  json['views']
      data.clicks = json['clicks']
      data.requests = json['requests']
      data.date = json['name']
      
      data.fill_rate = (1.0 * data.impressions / data.requests).to_s
      data.ecpm = (1.0 * data.revenue / data.impressions * 1000).to_s
      data.ctr = (1.0 * data.clicks / data.impressions).to_s
    end
  end

  class VideoEggSite < Site
    def get_data(username, password, ad_network_id1, app_name, ad_network_id3)
      uri = URI.parse("https://partners.videoegg.com/p/eap/h/1/Reports/partner_report" +
          "?type=csv&form=Package.login.login&doLogin=true" +
          "&input_login_username=#{username}" +
          "&input_login_password=#{password}" +
          "&tab=Site")

      @today_data = Data.new
      @yesterday_data = Data.new

      csv = download_content(uri, {}, 30)

      get_next_line = false
      today = true
      csv.each do |line|
        items = line.split(',')
        if get_next_line
          data = today ? @today_data : @yesterday_data
          data.date, data.impressions, data.ctr, data.revenue, data.ecpm = items
          data.ctr = data.ctr.gsub(/(\%|\$|\s)/, '')
          data.revenue = data.revenue.gsub(/(\%|\$|\s)/, '')
          data.ecpm = data.ecpm.gsub(/(\%|\$|\s)/, '')
          if today
            today = false
          else
            break
          end
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
