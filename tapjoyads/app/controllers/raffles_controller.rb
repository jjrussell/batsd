class RafflesController < ApplicationController
  
  layout 'iphone'
  
  APP_ID = 'TapNWinAppId'
  
  def index
    return unless verify_params([:udid], {:allow_empty => false})
    @raffles = RaffleTicket.get_active_raffles
    @point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{APP_ID}")

    @raffle = @raffles.first
    @prev_raffle = nil
    @next_raffle = @raffles[1]
    unless params[:raffle_id].blank?
      @raffles.size.times do |i|
        if @raffles[i].key == params[:raffle_id]
          @raffle = @raffles[i]
          @prev_raffle = @raffles[i - 1]
          @next_raffle = @raffles[i + 1]
        end
      end
    end
    
    @raffle.total_purchased = @raffle.get_realtime_total_purchased
  end
  
  def status
    return unless verify_params([:udid], {:allow_empty => false})
    
  end
  
  def purchase
    return unless verify_params([:udid], {:allow_empty => false})
    
    quantity = params[:quantity].to_i
    
    success, message = PointPurchases.purchase_virtual_good("#{params[:udid]}.#{APP_ID}", params[:id], quantity)
  
    if success
      flash[:notice] = "You successfully purchased #{quantity} raffle ticket"
      flash[:notice] += 's' if quantity > 1
      
      Mc.increment_count(RaffleTicket.get_total_purchased_memcached_key(params[:id]))
    else
      flash[:error] = message
    end

    redirect_to raffles_path(:udid => params[:udid], :raffle_id => params[:id])
  end
  
  def edit
    
  end
  
  def update
    
  end
end