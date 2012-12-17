class SupportRequest < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "support_requests", :read_from_riak => true

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

  def get_last_click(udid, offer)
    conditions = ["udid = ? and advertiser_app_id = ? and manually_resolved_at is null", udid, offer.item_id]
    Click.select_all(:conditions => conditions).max_by { |c| c.clicked_at.to_f }
  end

  def click
    Click.find(click_id)
  end

  private

  def fill(options)
    app         = options.delete(:app)        { nil }
    currency    = options.delete(:currency)   { nil }
    offer       = options.delete(:offer)      { nil }
    params      = options.delete(:params)     { |k| raise "#{k} is a required argument" }
    user_agent  = options.delete(:user_agent) { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    set_attrs(params)
    currency                    = Currency.find_in_cache(params[:currency_id]) unless currency.present?
    offer_click                 = offer.present? ? get_last_click(params[:udid], offer) : nil
    self.user_agent             = user_agent
    self.lives_in               = 'offerwall'
    self.app_id                 = app.try(:id) if self.app_id.blank?
    self.currency_id            = currency.try(:id) if self.currency_id.blank?
    self.managed_currency       = currency.try(:tapjoy_managed?)
    self.offer_id               = offer.try(:id) if self.offer_id.blank?
    self.click_id               = offer_click.try(:id) if self.click_id.blank?
    self.offer_value            = offer.try(:payment)
  end

  def set_attrs(params = {})
    columns = SupportRequest.attribute_names
    params.each { |k,v| self.put(k.to_s, v) if columns.include?(k.to_s) }
  end
end
