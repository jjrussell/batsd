class CcauthController < ApplicationController
  include DownloadContent
  include Patron
  
  def index
    begin
      last4 = get_last4(params[:x_trans_id])
    rescue
      render :text => 'last4 not found'
      return
    end
    
    response = PromotionEntry.select(:where => "promo_id='indietro' and last5 like '%#{last4}' and discount_applied is null")
    if response[:items].length == 0
      render :text => 'No match'
      return
    end
    
    entry = response[:items][0]
    phone = entry.get('phone')
    send_sms(phone)
    
    entry.put('discount_applied', Time.now.to_f.to_s)
    entry.save
    
    render :text => "sms sent"
  end
  
  private
  
  ##
  # returns the last 4 digits of a CC, given a transaction id.
  def get_last4(trans_id)
    login_url = 'https://account.authorize.net/UI/themes/anet/logon.aspx'
    url = "https://account.authorize.net/UI/themes/anet/popup.aspx?page=history&sub=printtrandetail&transid=#{trans_id}"
    
    sess = Session.new
    sess.handle_cookies
    login_page_content = sess.get(login_url).body
    view_state = login_page_content.match(/id="__VIEWSTATE" value="(.*)"/)[1]
    
    response = sess.post(login_url,
       "__VIEWSTATE=#{CGI::escape(view_state)}&__PAGE_KEY=&MerchantLogin=tapjoy1&Password=1Andover1",
       {'Content-Type'=> 'application/x-www-form-urlencoded'})
    
    response = sess.get(url, {'User-Agent'=> 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7'})
    last4 = response.body.match(/<td>XXXX(.*)<\/td>/)[1]
    return last4
  end
  
  def send_sms(phone)
    phone = "1" + phone unless phone.starts_with?('1')
    phone = "+" + phone
    
    message = "Thank you for eating at Indietro. You will receive $10 off on your credit card statement.\n" +
        "Explore nearby: http://bit.ly/19swDW"

    download_content("http://api.upsidewireless.com/soap/SMS.asmx/Send_Plain" +
        "?token=1ddcae34-b1a7-436d-8c48-04e61e5477cb" +
        "&signature=6IOfzlLbHFB8oAdhlgij2Et9" +
        "&recipient=#{phone}" +
        "&message=#{CGI::escape(message)}" +
        "&encoding=Seven")
    #download_content("http://www.bulksms.co.uk:5567/eapi/submission/send_sms/2/2.0?" +
    #    "username=tapjoy&password=business&message=#{CGI::escape(message)}&msisdn=#{phone}")
        
    TapjoyMailer.deliver_sms_sent(phone, message)
  end
  
end