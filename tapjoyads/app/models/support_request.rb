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

  def self.resolve(support_request_id)
    begin
      return 'No support request id provided' if support_request_id.nil? or support_request_id.empty?
      support_request = SupportRequest.new(:key => support_request_id)
      return "Invalid support_request_id: #{support_request_id}" if support_request.new_record?
      return "Unable to find the click associated with the request" if support_request.click_id.nil?
      click = Click.new(:key => support_request.click_id)
      return "Invalid click id: #{support_request.click_id} for the given support request: #{support_request.id}" if click.new_record?

      click.resolve!
    rescue Exception => e
      return "#{e}"
    end
    return nil
  end
end
