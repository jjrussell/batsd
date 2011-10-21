class GameStateController < ApplicationController
  include Curbit::Controller

  before_filter :get_mapping, :only => :load

  # rate_limit :save, :key => proc { |c| c.params[:udid] }, :max_calls => 5, :time_limit => 1.hour, :wait_time => 12.minutes, :message => :rate_limited

  def load
    return unless verify_params([:app_id, :udid, :publisher_user_id])
    @game_state = GameState.new :key => "#{params[:app_id]}.#{params[:publisher_user_id]}"
    @up_to_date = params[:version].present? && (params[:version].to_i == @game_state.version)
    @point_purchases = PointPurchases.new :key => "#{params[:publisher_user_id]}.#{params[:app_id]}"
    @currency = Currency.find_in_cache params[:app_id]
  end

  def save
    return unless verify_params([:app_id, :publisher_user_id, :data, :udid, :game_state_points])
    @game_state = GameState.new :key => "#{params[:app_id]}.#{params[:publisher_user_id]}"
    @game_state.data = params[:data]
    @game_state.version += 1
    @game_state.add_device params[:udid]
    @game_state.tapjoy_points = params[:game_state_points].to_i
    @game_state.save
  end

private

  def rate_limited(wait_time)
    render :rate_limited, :status => 420
  end

  def get_mapping
    if params[:publisher_user_id].blank?
      mapping = GameStateMapping.new :key => "#{params[:app_id]}.#{params[:udid]}"
      mapping.generate_publisher_user_id! if mapping.is_new
      params[:publisher_user_id] = mapping.publisher_user_id
    end
  end

end
