class FreeAppCountController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    publisher_app = SdbApp.new(:key => params[:app_id])
    advertiser_app_list = publisher_app.get_advertiser_app_list(params[:udid], 
        :iphone => (not params[:device_type] =~ /iPod/))
    
    @free_app_count = 0
    advertiser_app_list.each do |app|
      @free_app_count += 1 if app.is_free
    end
  end
end