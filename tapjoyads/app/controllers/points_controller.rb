class PointsController < ApplicationController
  def award
    return unless verify_params([ :app_id, :udid, :publisher_user_id, :tap_points, :guid, :timestamp, :verifier, :currency_id ])
    hash_bits = [
      params[:app_id],
      params[:udid],
      params[:timestamp],
      App.find_in_cache(params[:app_id]).secret_key,
      params[:tap_points],
      params[:guid],
    ]
    generated_key = Digest::SHA256.hexdigest(hash_bits.join(':'))

    unless params[:verifier] == generated_key
      @error_message = "invalid verifier"
      render :template => 'layouts/error' and return
    end

    currency = Currency.find_in_cache(params[:currency_id])
    return unless verify_records([ currency ])

    reward = Reward.new(:key => params[:guid])
    reward.type              = 'award_currency'
    reward.publisher_app_id  = params[:app_id]
    reward.currency_id       = currency.id
    reward.publisher_user_id = params[:publisher_user_id]
    reward.currency_reward   = params[:tap_points]
    reward.udid              = params[:udid]
    reward.country           = params[:country]

    begin
      reward.serial_save(:catch_exceptions => false, :expected_attr => { 'type' => nil })
    rescue Simpledb::ExpectedAttributeError => e
      @error_message = "points already awarded"
      render :template => 'layouts/error' and return
    end

    message = reward.serialize(:attributes_only => true)

    Sqs.send_message(QueueNames::SEND_CURRENCY, message)
    @message = "Points awarded"
    render :template => 'layouts/success'
  end
end
