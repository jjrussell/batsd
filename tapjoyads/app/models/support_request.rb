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
    self.description            = params[:description]
    self.udid                   = params[:udid]
    self.email_address          = params[:email_address]
    self.publisher_app_id       = params[:publisher_app_id]
    self.publisher_partner_id   = params[:publisher_partner_id]
    self.publisher_user_id      = params[:publisher_user_id]
    self.device_type            = params[:device_type]
    self.user_agent             = user_agent
    self.language_code          = params[:language_code]
    self.app_id                 = app.id
    self.currency_id            = currency.id
    self.offer_id               = offer.id if offer.present?
    click                       = offer.present? ? get_last_click(params[:udid], offer) : nil
    self.click_id               = click ? click.id : nil
  end

  def fill_from_click(click, params, device, gamer, user_agent)
    self.udid                   = device.device_id
    self.description            = params[:description]
    self.email_address          = gamer.email
    self.publisher_app_id       = click.present? ? click.publisher_app_id : params[:publisher_app_id]
    self.publisher_partner_id   = click.present? ? click.publisher_partner_id : params[:publisher_partner_id]
    self.publisher_user_id      = click.present? ? click.publisher_user_id : params[:publisher_user_id]
    self.device_type            = device.device_type
    self.user_agent             = user_agent
    self.language_code          = params[:language_code]
    self.app_id                 = click.present? ? click.offer.item_id : params[:app_id]
    self.currency_id            = click.present? ? click.currency_id : params[:currency_id]
    self.offer_id               = click.present? ? click.offer_id : params[:offer_id]
    self.click_id               = click.present? ? click.id : nil
    self.gamer_id               = gamer.id
  end

  def get_last_click(udid, offer)
    conditions = ActiveRecord::Base.sanitize_conditions("udid = ? and advertiser_app_id = ? and manually_resolved_at is null", udid, offer.item_id)
    clicks = Click.select_all(:conditions => conditions)
    clicks.sort_by { |c| c.clicked_at.to_f }.last
  end

  def click
    Click.find(click_id)
  end
end
