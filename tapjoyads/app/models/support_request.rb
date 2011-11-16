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
    self.offer_name        = params[:offer_name]
    self.app_id            = app.id
    self.currency_id       = currency.id
    self.offer_id          = offer.id if offer.present?
    click                  = get_last_click(params[:udid], offer)
    self.click_id          = click ? click.id : nil

  end

  def get_last_click(udid, offer)
    if offer.present?
      #Lookup based on offer id. Almost all requests should have one.
      #Especially since we are not accepting requests without an offer.
      clicks = Click.find_all_by_udid_and_offer_id(udid, offer.id)
      if clicks.empty?
        return nil
      end
      click = clicks.sort_by { |c| c.clicked_at }.last
      if click.installed_at? || click.manually_resolved_at?
        return nil
      end
      return click
    end
    return nil
  end
end
