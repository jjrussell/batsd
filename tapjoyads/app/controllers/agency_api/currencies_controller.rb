class AgencyApi::CurrenciesController < AgencyApiController
  
  def create
    return unless verify_request([ :app_id, :name, :conversion_rate ])
    
    app = App.find_by_id(params[:app_id])
    unless app.present?
      render_error('app not found', 400)
      return
    end
    
    return unless verify_partner(app.partner_id)
    
    unless app.primary_currency.nil?
      render_error('currency already exists', 400)
      return
    end
    
    currency = Currency.new
    log_activity(currency)
    currency.id = app.id
    currency.app = app
    currency.partner = @partner
    currency.name = params[:name]
    currency.conversion_rate = params[:conversion_rate]
    currency.initial_balance = params[:initial_balance] if params[:initial_balance].present?
    currency.test_devices = params[:test_devices] if params[:test_devices].present?
    currency.minimum_featured_bid = params[:minimum_featured_bid] if params[:minimum_featured_bid].present?
    currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
    currency.ordinal = 1
    unless currency.valid?
      render_error(currency.errors, 400)
      return
    end
    currency.save!
    
    save_activity_logs
    render_success({ :currency_id => currency.id })
  end
  
  def update
    return unless verify_request([ :id ])
    
    currency = Currency.find_by_id(params[:id])
    unless currency.present?
      render_error('currency not found', 400)
      return
    end
    
    return unless verify_partner(currency.partner_id)
    
    log_activity(currency)
    currency.name = params[:name] if params[:name].present?
    currency.conversion_rate = params[:conversion_rate] if params[:conversion_rate].present?
    currency.initial_balance = params[:initial_balance] if params[:initial_balance].present?
    currency.test_devices = params[:test_devices] if params[:test_devices].present?
    currency.minimum_featured_bid = params[:minimum_featured_bid] if params[:minimum_featured_bid].present?
    unless currency.valid?
      render_error(currency.errors, 400)
      return
    end
    currency.save!
    
    save_activity_logs
    render_success
  end
  
end
