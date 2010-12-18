class OptOutsController < ApplicationController
  
  def create
    unless params[:udid].blank?
      d = Device.new(:key => params[:udid])
      d.opted_out = true
      d.save
    end
    redirect_to '/privacy.html'
  end
  
end
