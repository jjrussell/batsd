class AgencyApi::CurrenciesController < AgencyApiController

  def index
    return unless verify_request([ :app_id ])

    app = App.find_by_id(params[:app_id])
    unless app.present?
      render_error('app not found', 400)
      return
    end

    return unless verify_partner(app.partner_id)

    currencies = app.currencies.map do |currency|
      {
        :currency_id     => currency.id,
        :name            => currency.name,
        :conversion_rate => currency.conversion_rate,
        :initial_balance => currency.initial_balance,
        :test_devices    => currency.test_devices,
        :callback_url    => currency.callback_url,
        :secret_key      => currency.secret_key,
      }
    end

    render_success({ :currencies => currencies })
  end

  def show
    return unless verify_request([ :id ])

    currency = Currency.find_by_id(params[:id])
    unless currency.present?
      render_error('currency not found', 400)
      return
    end

    return unless verify_partner(currency.partner_id)

    result = {
      :currency_id     => currency.id,
      :name            => currency.name,
      :conversion_rate => currency.conversion_rate,
      :initial_balance => currency.initial_balance,
      :test_devices    => currency.test_devices,
      :callback_url    => currency.callback_url,
      :secret_key      => currency.secret_key,
    }
    render_success(result)
  end

  def create
    return unless verify_request([ :app_id, :name, :conversion_rate ])

    app = App.find_by_id(params[:app_id])
    unless app.present?
      render_error('app not found', 400)
      return
    end

    return unless verify_partner(app.partner_id)

    unless app.can_have_new_currency?
      render_error('currency already exists', 400)
      return
    end

    currency = Currency.new
    log_activity(currency)

    currency.app = app
    currency.partner = @partner
    currency.name = params[:name]
    currency.conversion_rate = params[:conversion_rate]
    currency.initial_balance = params[:initial_balance] if params[:initial_balance].present?
    currency.test_devices = params[:test_devices] if params[:test_devices].present?
    if params[:callback_url].present?
      currency.callback_url = params[:callback_url]
    else
      currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
    end
    currency.secret_key = params[:secret_key] if params[:secret_key].present?
    currency.ordinal = app.currencies.size + 1

    if app.currencies.empty?
      currency.id = app.id
    elsif currency.tapjoy_managed?
      render_error('cannot have multiple tapjoy managed currencies', 400)
      return
    end

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
    currency.callback_url = params[:callback_url] if params[:callback_url].present?
    currency.secret_key = params[:secret_key] if params[:secret_key].present?
    unless currency.valid?
      render_error(currency.errors, 400)
      return
    end
    currency.save!

    save_activity_logs
    render_success
  end

end
