class PointsController < ApplicationController
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

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    reward = Reward.new(:key => params[:guid])
    reward.type              = 'award_currency'
    reward.publisher_app_id  = params[:app_id]
    reward.currency_id       = @currency.id
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

    @success = true
    @message = "#{params[:tap_points]} points awarded"
    @point_purchases = PointPurchases.new(:key => "#{params[:publisher_user_id]}.#{params[:app_id]}")
    @point_purchases.points += params[:tap_points].to_i

    web_request = WebRequest.new
    web_request.put_values('award_points', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    web_request.save

    Sqs.send_message(QueueNames::SEND_CURRENCY, message)

    render :template => 'get_vg_store_items/user_account'
  end

  def spend
    return unless verify_params([:app_id, :udid, :tap_points])

    #TO REMOVE: hackey stuff for doodle buddy, remove on Jan 1, 2011
    doodle_buddy_holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    doodle_buddy_regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    params[:app_id] = doodle_buddy_regular_id if params[:app_id] == doodle_buddy_holiday_id

    if params[:publisher_user_id].present?
      publisher_user_id = params[:publisher_user_id]
    else
      publisher_user_id = params[:udid]
      params[:publisher_user_id] = params[:udid]
    end

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    pp_key = "#{publisher_user_id}.#{params[:app_id]}"
    tap_points = params[:tap_points].to_i
    if tap_points == 0
      @point_purchases = PointPurchases.new(:key => pp_key)
    else
      @success, @message, @point_purchases = PointPurchases.spend_points(pp_key, tap_points)
    end

    if @success
      web_request = WebRequest.new
      web_request.put_values('spend_points', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
      web_request.save
    end

    render :template => 'get_vg_store_items/user_account'
  end

  def purchase_vg
    return unless verify_params([:app_id, :udid, :virtual_good_id])

    #TO REMOVE: hackey stuff for doodle buddy, remove on Jan 1, 2011
    doodle_buddy_holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    doodle_buddy_regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    params[:app_id] = doodle_buddy_regular_id if params[:app_id] == doodle_buddy_holiday_id

    publisher_user_id = params[:udid]
    publisher_user_id = params[:publisher_user_id] unless params[:publisher_user_id].blank?

    @currency = Currency.find_in_cache(params[:app_id])
    return unless verify_records([ @currency ])

    @success, @message, @point_purchases = PointPurchases.purchase_virtual_good("#{publisher_user_id}.#{params[:app_id]}", params[:virtual_good_id])

    if @success
      web_request = WebRequest.new
      web_request.put_values('purchased_vg', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
      web_request.save
    end

    render :template => 'get_vg_store_items/user_account'
  end
end
