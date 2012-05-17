class PointsController < ApplicationController

  before_filter :lookup_udid, :set_publisher_user_id

  GLU_PARTNER_ID = '28239536-44dd-417f-942d-8247b6da0e84'
  OTHER_APPS_TO_BLOCK = [
    '591febdc-663b-4305-853c-f80ea9ba01db',
    'a1ba1211-90d0-4b3c-a6d4-8fe2bdf2d8bb',
    '91d5805e-17e8-4de9-96e2-656c8fae2305',
    '6e1c1d3d-ae0e-45c2-b139-e98b74586492',
    '8d1f3529-6f60-4391-ae3b-e4dedb99df66',
    '5ad19a22-69b6-4396-96ab-522bc247c514',
    '2f49aacc-d9fe-47ce-924e-16d515660808',
    'f50242be-dcbc-4488-b302-1d8de75718b4', ]

  def award
    return unless verify_params([ :app_id, :udid, :publisher_user_id, :tap_points, :guid, :timestamp, :verifier ])

    unless params[:verifier] == generate_verifier([ params[:tap_points], params[:guid] ])
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
      reward.save!(:expected_attr => { 'type' => nil })
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

    if tap_points < 0 && (@currency.partner_id == GLU_PARTNER_ID || OTHER_APPS_TO_BLOCK.include?(@currency.app_id))
      @error_message = "tap_points must be greater than zero"
      render :template => 'layouts/error' and return
    end

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
      web_request.put_values(path, params, ip_address, geoip_data, request.headers['User-Agent'])
      web_request.save
    end
  end
end
