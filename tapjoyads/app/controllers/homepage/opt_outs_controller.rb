class Homepage::OptOutsController < ApplicationController

  def create
    unless params[:udid].blank?
      d = Device.new(:key => params[:udid])
      d.opted_out = true
      d.save
      flash[:notice] = "This device (#{params[:udid]}) has been successfully opted out."
    end
    redirect_to :back
  end

end
