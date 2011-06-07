class GamesController < ApplicationController
  include SslRequirement
  
  layout 'games'
  
  skip_before_filter :fix_params
  
protected
  
  def ssl_required?
    Rails.env == 'production'
  end
  
end
