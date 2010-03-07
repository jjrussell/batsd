class EnterPromotionController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid])
    
    pe = PromotionEntry.new(:key => "#{params[:udid]}.#{params[:promo_id]}")
    pe.put('last5', params[:last5])
    pe.put('email', params[:email])
    pe.put('phone', params[:phone])
    pe.put('udid', params[:udid])
    pe.put('app_id', params[:app_id])
    
    pe.save

    render :template => 'layouts/success'
  end
end