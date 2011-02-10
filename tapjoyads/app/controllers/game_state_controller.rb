class GameStateController < ApplicationController
  def load
    return unless verify_params([:app_id, :publisher_user_id])
    
    @game_state = GameState.new :key => "#{params[:app_id]}.#{params[:publisher_user_id]}"
  end
  
  def save
    return unless verify_params([:app_id, :publisher_user_id, :data])
    @game_state = GameState.new :key => "#{params[:app_id]}.#{params[:publisher_user_id]}"
    @game_state.data = params[:data]
    @game_state.version += 1
    @game_state.save
  end
end
