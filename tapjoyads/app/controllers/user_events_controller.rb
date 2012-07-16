class UserEventsController < ApplicationController

  def create
    begin
      event = UserEvent.new
      event.put_values(params, ip_address, geoip_data, request.headers['User-Agent'])
      event.save
      render :text => "#{I18n.t('user_event.success.created')}\n", :status => :ok
    rescue Exception => error
      render :text => "#{error.message}\n", :status => :bad_request
    end
  end

end
