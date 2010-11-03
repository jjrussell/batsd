class FreeAppCountController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid])
    
    currency = Currency.find_in_cache(params[:app_id])
    publisher_app = App.find_in_cache(params[:app_id])
    offer_list, more_data_available = publisher_app.get_offer_list(params[:udid], 
        :currency => currency,
        :device_type => params[:device_type])
    
    @free_app_count = 0
    offer_list.each do |offer|
      @free_app_count += 1 if offer.is_free?
    end
  end
end
