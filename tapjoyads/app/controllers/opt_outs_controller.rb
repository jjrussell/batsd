class OptOutsController < ApplicationController
  
  def create
    d = Device.new(:key => params[:udid])
    d.opted_out = true
    d.save
    redirect_to '/privacy.html'
  end
  
end
