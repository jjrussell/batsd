require 'net/https'
require 'hpricot'
require 'cgi'
require 'patron'
require 'json'

class Cron::GetAdNetworkDataController < ApplicationController
  include DownloadContent
  include AuthenticationHelper
  
  before_filter 'authenticate'
  
  def initialize
    @adnetwork_map = {
      '78c4f8c0-4940-4d59-97fe-16bc44981657' => VideoEggSite,
      'f2eb272c-1783-4589-99a0-667e1a45ac51' => MillennialSite,
      '' => AdfonicSite
    }
  end
  
  def index
    url = "http://tapjoyconnect.com/CronService.asmx/GetAdCampaign?password=taptapcampaign"
    content = download_content(url, {}, 30)
    
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
      logger.warn "Failed to get data: #{e}"
      render :text => "FAIL: #{site.name}: #{e}"
    else
      render :text => "OK: #{site.name}"
    end
  end
  
  def test
    site = AdfonicSite.new
    render :text => site.get_data('partners@tapjoy.com', 'business', 'TapDefense', nil, nil)
    
    campaign_id = 'asdd'
    report_data(campaign_id, site.today_data)
    report_data(campaign_id, site.yesterday_data)

  end
  
  private
  
  def report_data(campaign_id, data)
    unless data.date
      logger.debug "No data"
      return
    end
      
    url = "http://tapjoyconnect.com/CronService.asmx/SubmitAdCampaignData" +
        "?AdCampaignID=#{campaign_id.to_s}" +
        "&eCPM=#{data.ecpm.to_s}" +
        "&Revenue=#{data.revenue.to_s}" +
        "&Impressions=#{data.impressions.to_s}" +
        "&FillRate=#{data.fill_rate.to_s}" +
        "&Clicks=#{data.clicks.to_s}" +
        "&Requests=#{data.requests.to_s}" +
        "&CTR=#{data.ctr.to_s}" + 
        "&Date=#{data.date.to_s}"
    
    response = download_content(url, {}, 30)
    doc = Hpricot.parse(response)
    response_string = doc.search('//string').first.inner_text
   
    logger.info "Callback response: '#{response_string}'"
  end
  
  class Data
    attr_accessor :ecpm, :revenue, :impressions, :fill_rate, :clicks, :requests, :ctr, :date
  end

  class Site
    include DownloadContent
    attr_accessor :today_data, :yesterday_data, :name
  end

  class AdfonicSite < Site
    def initialize
      @name = "Adfonic"
    end
    
    def get_data(username, password, publication_name, ad_network_id2, ad_network_id3)
      sess = Patron::Session.new
      sess.handle_cookies
      sess.timeout = 10
      sess.base_url = 'adfonic.com'
      sess.get('/')
      sess.post('/', 'loginForm=loginForm&loginForm%3AhiddenSubmit=' +
          "&loginForm%3Aemail=#{CGI::escape(username)}" +
          "&loginForm%3Aj_id_jsp_1414384550_14=#{password}" +
          '&javax.faces.ViewState=j_id1%3Aj_id2')
      
      page_content = sess.get('/sites-and-apps/reporting/sites-and-apps').body
      
      doc = Hpricot.parse(page_content)
      view_state_param = doc.search('input[@id=javax.faces.ViewState]').first['value']
      # Must use the # notation with no tag name, since the id contains a ':'
      end_date_string = doc.search('#reportForm:endDate').first['value']
      
      day, month, year = end_date_string.split('/')
      start_date = Time.parse("#{year}-#{month}-#{day}") - 24 * 60 * 60
      start_date_string = "#{start_date.day}/#{start_date.month}/#{start_date.year.to_s[2,3]}"

      publication_id = ''
      options = doc.search('#reportForm:publication/option')
      options.each do |option|
        if option.inner_text.strip.downcase.eql?(publication_name.downcase)
          publication_id = option['value']
        end
      end
      raise "Publication not found (#{publication_name})" if publication_id == ''
      
      response = sess.post('/sites-and-apps/reporting/sites-and-apps', 'reportForm=reportForm' +
            "&reportForm%3Apublication=#{CGI::escape(publication_id)}" +
            "&reportForm%3AstartDate=#{CGI::escape(start_date_string)}" +
            "&reportForm%3AendDate=#{CGI::escape(end_date_string)}" +
            "&javax.faces.ViewState=#{CGI::escape(view_state_param)}" +
            '&reportForm%3Aj_id_jsp_2115318982_13=reportForm%3Aj_id_jsp_2115318982_13')
          
      csv = sess.get('/sites-and-apps/reporting/csv').body
      
      @today_data = Data.new
      @yesterday_data = Data.new
      csv.each do |line|
        line = line.gsub(/\s/, '')
        next if line.length == 0
        
        items = line.split(',')
        data = nil
        if items[0].include? start_date_string
          data = @yesterday_data
        elsif items[0].include? end_date_string
          data = @today_data
        end
        if data
          get_data_from_csv_line(data, items)
        end
      end
      
      return csv
    end
    
    def get_data_from_csv_line(data, line_items)
      items = []
      line_items.each do |item|
        items.push(item.gsub('"', ''))
      end
      
      day, month, year = items[0].split('/')
      date = Time.parse("#{year}-#{month}-#{day}")
      data.date = "#{date.month}-#{date.day}-#{date.year}"
      
      data.requests = items[1]
      data.impressions = items[2]
      data.fill_rate = items[3]
      data.clicks = items[4]
      data.ctr = items[5]
      data.ecpm = items[6]
      data.revenue = items[7]
    end
  end

  class MillennialSite < Site
    def initialize
      @name = "Millennial"
    end
    
    def get_data(username, password, ad_network_id1, site_id, ad_network_id3)
      sess = Patron::Session.new
      sess.handle_cookies
      sess.base_url = 'clients.millennialmedia.com'
      sess.post('/', "username=#{username}&password=#{password}")
      
      response = sess.get("/publisher/publisher-statistics-default.php5?" +
          "siteid=#{site_id}&timecheck=DX7&drawer=statistics")
      content = response.body
      
      json_match = content.match(/var rootReportObj = (\{.*\})\;/)
      
      unless json_match
        raise "Could not log in to user: #{username}"
      end
      json_string = json_match[1]
      
      json = JSON.parse(json_string)
      
      values = []
      
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
      
      return data
    end
  end

  class VideoEggSite < Site
    def initialize
      @name = "VideoEgg"
    end
    
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
