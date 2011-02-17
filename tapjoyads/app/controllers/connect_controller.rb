class ConnectController < ApplicationController

  def index
    return unless verify_params([:app_id, :udid])
    
    @country = nil
    
    Rails.logger.info_with_time("Check conversions and maybe add to sqs") do
      click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      unless (click.attributes.empty? || click.installed_at)
        @country = click.country if click.clicked_at > (Time.zone.now - 2.days)
        logger.info "Added conversion to sqs queue"
        message = { :click => click.serialize(:attributes_only => true), :install_timestamp => Time.zone.now.to_f.to_s }.to_json
        Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
      end
    end
    
    if params[:transaction_id].present? && Rails.env == 'production'
      message = { :url => "http://mc1.myofferpal.com/confirm/confirm.pl?adnet=tj&subid=#{params[:transaction_id]}", :download_options => { :timeout => 30 } }.to_json
      Sqs.send_message(QueueNames::FAILED_DOWNLOADS, message)
    end
    
    web_request = WebRequest.new
    web_request.put_values('connect', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    
    device = Device.new(:key => params[:udid])
    path_list = device.set_app_ran(params[:app_id], params)
    path_list.each do |path|
      web_request.add_path(path)
    end
    
    device.save
    
    web_request.save
  end
end
