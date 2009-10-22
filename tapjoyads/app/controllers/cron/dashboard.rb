class Cron::Dashboard < ApplicationController
  before_filter 'authenticate_cron'
  
  def index
    render :text => "hi"
  end