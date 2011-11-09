class BanController < ApplicationController

  def create
    unless params[:udid].blank?
      d = Device.new(:key => params[:udid])
      d.banned = true
      d.save
      flash[:notice] = "This device (#{params[:udid]}) has been banned."
    end
    redirect_to :back
  end

end

