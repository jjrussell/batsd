class PointsController < ApplicationController

  before_filter :set_publisher_user_id, :only => [ :spend, :purchase_vg, :consume_vg ]

  def award
    return unless verify_params([ :app_id, :udid, :publisher_user_id, :tap_points, :guid, :timestamp, :verifier ])
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

    tap_points = params[:tap_points].to_i
    unless tap_points > 0
      @error_message = "tap_points must be greater than zero"
      render :template => 'layouts/error' and return
    end

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    reward = Reward.new(:key => params[:guid])
    reward.type              = 'award_currency'
    reward.publisher_app_id  = params[:app_id]
    reward.currency_id       = @currency.id
    reward.publisher_user_id = params[:publisher_user_id]
    reward.currency_reward   = tap_points
    reward.udid              = params[:udid]
    reward.country           = params[:country]

    begin
      reward.serial_save(:catch_exceptions => false, :expected_attr => { 'type' => nil })
    rescue Simpledb::ExpectedAttributeError => e
      @error_message = "points already awarded"
      render :template => 'layouts/error' and return
    end

    @success = true
    @message = "#{tap_points} points awarded"
    @point_purchases = PointPurchases.new(:key => "#{params[:publisher_user_id]}.#{params[:app_id]}")
    @point_purchases.points += tap_points

    check_success('award_points')

    Sqs.send_message(QueueNames::SEND_CURRENCY, reward.key)

    render :template => 'get_vg_store_items/user_account'
  end

  def spend
    return unless verify_params([:app_id, :udid, :tap_points, :publisher_user_id])

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    pp_key = "#{params[:publisher_user_id]}.#{params[:app_id]}"
    tap_points = params[:tap_points].to_i
    if tap_points == 0
      @success = true
      @message = ''
      @point_purchases = PointPurchases.new(:key => pp_key)
    else
      @success, @message, @point_purchases = PointPurchases.spend_points(pp_key, tap_points)
    end
    check_success('spend_points')

    render :template => 'get_vg_store_items/user_account'
  end

  def purchase_vg
    return unless verify_params([:app_id, :udid, :virtual_good_id, :publisher_user_id])

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    quantity = params[:quantity].blank? ? 1 : params[:quantity].to_i
    @success, @message, @point_purchases = PointPurchases.purchase_virtual_good("#{params[:publisher_user_id]}.#{params[:app_id]}", params[:virtual_good_id], quantity)
    check_success('purchased_vg')

    render :template => 'get_vg_store_items/user_account'
  end

  def consume_vg
    return unless verify_params([:app_id, :udid, :virtual_good_id, :publisher_user_id])

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    quantity = params[:quantity].blank? ? 1 : params[:quantity].to_i

    @success, @message, @point_purchases = PointPurchases.consume_virtual_good("#{params[:publisher_user_id]}.#{params[:app_id]}", params[:virtual_good_id], quantity)
    check_success('consumed_vg')

    render :template => 'get_vg_store_items/user_account'
  end

private

  def check_success(path)
    if @success
      web_request = WebRequest.new
      web_request.put_values(path, params, ip_address, get_geoip_data, request.headers['User-Agent'])
      web_request.save
    end
  end
end
