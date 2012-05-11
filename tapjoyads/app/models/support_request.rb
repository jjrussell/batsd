class SupportRequest < SimpledbResource
  belongs_to :device, :foreign_key => 'udid'
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :publisher_partner, :class_name => 'Partner'
  belongs_to :currency
  belongs_to :offer
  belongs_to :click, :foreign_key => 'key'
  belongs_to :gamer

  self.domain_name = 'support_requests'

  self.sdb_attr :udid
  self.sdb_attr :description
  self.sdb_attr :email_address
  self.sdb_attr :publisher_app_id
  self.sdb_attr :publisher_partner_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :device_type
  self.sdb_attr :user_agent
  self.sdb_attr :language_code
  self.sdb_attr :offer_name
  self.sdb_attr :app_id
  self.sdb_attr :currency_id
  self.sdb_attr :offer_id
  self.sdb_attr :click_id
  self.sdb_attr :gamer_id

  def fill_from_params(params, app, currency, offer, user_agent)
    fill( :params     => params,
          :app        => app,
          :currency   => currency,
          :offer      => offer,
          :user_agent => user_agent )
  end

  def fill_from_click(click, params, device, gamer, user_agent)
    fill( :click      => click,
          :params     => params,
          :device     => device,
          :gamer      => gamer,
          :user_agent => user_agent )
  end

  def get_last_click(udid, offer)
    conditions = ["udid = ? and advertiser_app_id = ? and manually_resolved_at is null", udid, offer.item_id]
    clicks = Click.select_all(:conditions => conditions)
    clicks.sort_by { |c| c.clicked_at.to_f }.last
  end

  def click
    Click.find(click_id)
  end

  private

  def fill(options)
    app         = options.delete(:app)        { nil }
    currency    = options.delete(:currency)   { nil }
    click       = options.delete(:click)      { nil }
    device      = options.delete(:device)     { nil }
    gamer       = options.delete(:gamer)      { nil }
    offer       = options.delete(:offer)      { nil }
    params      = options.delete(:params)     { |k| raise "#{k} is a required argument" }
    user_agent  = options.delete(:user_agent) { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    self.user_agent             = user_agent
    self.description            = params[:description]
    self.language_code          = params[:language_code]

    self.publisher_app_id       = click.present? ? click.publisher_app_id : params[:publisher_app_id]
    self.publisher_partner_id   = click.present? ? click.publisher_partner_id : params[:publisher_partner_id]
    self.publisher_user_id      = click.present? ? click.publisher_user_id : params[:publisher_user_id]
    self.udid                   = device.present? ? device.device_id : params[:udid]
    self.device_type            = device.present? ? device.device_type : params[:device_type]
    self.email_address          = gamer.present? ? gamer.email : params[:email_address]
    self.gamer_id               = gamer.present? ? gamer.id : nil

    if click.present?
      self.app_id               = click.offer.item_id
      self.currency_id          = click.currency_id
      self.offer_id             = click.offer_id
      self.click_id             = click.id
    else
      self.app_id               = app.present? ? app.id : params[:app_id]
      self.currency_id          = currency.present? ? currency.id : params[:currency_id]
      self.offer_id             = offer.present? ? offer.id : nil
      offer_click               = offer.present? ? get_last_click(params[:udid], offer) : nil
      self.click_id             = offer_click.present? ? offer_click.id : nil
    end
  end
end
