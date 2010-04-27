class BalancesController < ApplicationController
  
  def show
    partner = Partner.find(params[:id])
    render :text => "#{partner.balance},#{partner.pending_earnings}"
  end
  
end
