class GameStateController < ApplicationController
  def load
    return unless verify_params([:app_id, :publisher_user_id])
    @game_state = GameState.new :key => "#{params[:app_id]}.#{params[:publisher_user_id]}"
    @point_purchases = PointPurchases.new :key => "#{params[:publisher_user_id]}.#{params[:app_id]}"
    @currency = Currency.find_in_cache params[:app_id]
  end
  
  def save
    return unless verify_params([:app_id, :publisher_user_id, :data, :udid])
    params[:spend] ||= 0
    @game_state = GameState.new :key => "#{params[:app_id]}.#{params[:publisher_user_id]}"
    @game_state.data = params[:data]
    @game_state.version += 1
    @game_state.add_device params[:udid]
    @game_state.tapjoy_spend += params[:spend].to_i
    @game_state.save!
    render :status => :ok, :text => "Success"
  end
  
end
