module RewardHelper

  def calculate_install_payouts(params)
    currency = params.fetch(:currency)
    advertiser_app = params.fetch(:advertiser_app)
    
    advertiser_amount_float = advertiser_app.get('payment_for_install').to_f
    publisher_amount_float = advertiser_amount_float.to_f * currency.get('installs_money_share').to_f
    offerpal_amount = ((1.0 - currency.get('installs_money_share').to_f) / 2.0 * advertiser_amount_float).to_i
    tapjoy_amount = advertiser_amount_float.to_i - publisher_amount_float.to_i - offerpal_amount.to_i
    currency_reward = [publisher_amount_float.to_i * currency.get('conversion_rate').to_f / 100.0, 1.0].max
    
    return {
      :advertiser_amount => (-advertiser_amount_float.to_i).to_s,
      :publisher_amount => publisher_amount_float.to_i.to_s,
      :tapjoy_amount => tapjoy_amount.to_s,
      :offerpal_amount => offerpal_amount.to_s,
      :currency_reward => currency_reward.to_i.to_s
      }
  end

  def calculate_offer_payouts(params)
    currency = params.fetch(:currency)
    offer_amount = params.fetch(:offer_amount).to_f
    
    advertiser_amount_float = offer_amount
    publisher_amount_float = advertiser_amount_float.to_f * currency.get('offers_money_share').to_f
    offerpal_amount = 0
    tapjoy_amount = advertiser_amount_float.to_i - publisher_amount_float.to_i - offerpal_amount.to_i
    currency_reward = [publisher_amount_float.to_i * currency.get('conversion_rate').to_f / 100.0, 1.0].max
    
    return {
      :advertiser_amount => (-advertiser_amount_float.to_i).to_s,
      :publisher_amount => publisher_amount_float.to_i.to_s,
      :tapjoy_amount => tapjoy_amount.to_s,
      :offerpal_amount => offerpal_amount.to_s,
      :currency_reward => currency_reward.to_i.to_s      
      }
  end
  
end