class SupportRequest < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "support_requests"

  belongs_to :device, :foreign_key => 'tapjoy_device_id'
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :publisher_partner, :class_name => 'Partner'
  belongs_to :currency
  belongs_to :offer
  belongs_to :click, :foreign_key => 'key'
  belongs_to :gamer

  REQUEST_SOURCE = 'offerwall'

  self.domain_name = 'support_requests'

  self.sdb_attr :udid
  self.sdb_attr :tapjoy_device_id
  self.sdb_attr :advertising_id
  self.sdb_attr :mac_address
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
  self.sdb_attr :managed_currency, :type => :bool
  self.sdb_attr :offer_id
  self.sdb_attr :click_id
  self.sdb_attr :gamer_id
  self.sdb_attr :offer_value, :type => :int
  self.sdb_attr :lives_in
  self.sdb_attr :click_source
  self.sdb_attr :mac_address

  def fill_from_params(params, app, currency, offer, user_agent)
    fill( :params     => params,
          :app        => app,
          :currency   => currency,
          :offer      => offer,
          :user_agent => user_agent )
  end

  def get_last_click(device_id, offer)
    conditions = ["tapjoy_device_id = ? or udid = ? and advertiser_app_id = ? and manually_resolved_at is null", device_id, device_id, offer.item_id]
    clicks = Click.select_all(:conditions => conditions)
    clicks.max_by { |c| c.clicked_at.to_f }
  end

  def click
    Click.find(click_id)
  end

  def tapjoy_device_id
    get('tapjoy_device_id') || udid
  end

  def tapjoy_device_id=(tj_id)
    put('tapjoy_device_id', tj_id)
  end

  def self.find_support_request(udid, device_id, pub_app_id)
    SupportRequest.find(:first, :conditions => ["tapjoy_device_id = ? or udid = ? and app_id = ?", device_id, udid, pub_app_id])
  end

  private

  def fill(options)
    app           = options.delete(:app)        { nil }
    currency      = options.delete(:currency)   { nil }
    offer         = options.delete(:offer)      { nil }
    params        = options.delete(:params)     { |k| raise "#{k} is a required argument" }
    user_agent    = options.delete(:user_agent) { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    self.user_agent             = user_agent
    self.description            = params[:description]
    self.language_code          = params[:language_code]
    self.publisher_app_id       = params[:publisher_app_id]
    self.publisher_partner_id   = params[:publisher_partner_id]
    self.publisher_user_id      = params[:publisher_user_id]
    self.udid                   = params[:udid]
    self.tapjoy_device_id       = params[:tapjoy_device_id]
    self.advertising_id         = params[:advertising_id]
    self.mac_address            = params[:mac_address]
    self.device_type            = params[:device_type]
    self.email_address          = params[:email_address]

    currency = Currency.find_in_cache(params[:currency_id]) unless currency.present?

    self.managed_currency       = currency.try(:tapjoy_managed?)
    self.lives_in               = REQUEST_SOURCE
    self.app_id                 = app.present? ? app.id : params[:app_id]
    self.currency_id            = currency.present? ? currency.id : params[:currency_id]
    self.offer_id               = offer.present? ? offer.id : nil
    offer_click                 = offer.present? ? get_last_click(params[:tapjoy_device_id], offer) : nil
    self.click_id               = offer_click.present? ? offer_click.id : nil
    self.offer_value            = offer.present? ? offer.payment : nil
  end
end
