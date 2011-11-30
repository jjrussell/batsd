class SupportRequest < SimpledbResource

  self.domain_name = 'support_requests'

  self.sdb_attr :udid
  self.sdb_attr :description
  self.sdb_attr :email_address
  self.sdb_attr :publisher_user_id
  self.sdb_attr :device_type
  self.sdb_attr :language_code
  self.sdb_attr :offer_name
  self.sdb_attr :app_id
  self.sdb_attr :currency_id
  self.sdb_attr :offer_id
  self.sdb_attr :click_id

  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
  end

  def serial_save(options = {})
    super({:write_to_memcache => false}.merge(options))
  end

  def fill(params, app, currency, offer)
    self.description       = params[:description]
    self.udid              = params[:udid]
    self.email_address     = params[:email_address]
    self.publisher_user_id = params[:publisher_user_id]
    self.device_type       = params[:device_type]
    self.language_code     = params[:language_code]
    self.app_id            = app.id
    self.currency_id       = currency.id
    self.offer_id          = offer.id if offer.present?
    click                  = offer.present? ? get_last_click(params[:udid], offer) : nil
    self.click_id          = click ? click.id : nil

  end

  def get_last_click(udid, offer)
    conditions = "udid = '#{udid}' and offer_id = '#{offer.id}' and installed_at is null and manually_resolved_at is null"
    clicks = Click.select_all(:conditions => conditions)
    clicks.sort_by { |c| c.clicked_at.to_f }.last
  end

  def click
    click = Click.new(:key => click_id)
    click.new_record? ? nil : click
  end
end
