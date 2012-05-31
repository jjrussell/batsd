class Games::PartnersController < GamesController

  def show
    partner_id = ObjectEncryptor.decrypt(params[:id]) if params[:id].present?
    device = Device.new(:key => current_device_id) if current_device_id.present?
    @partner = Partner.find(partner_id) if partner_id.present?
    if device.present? && @partner.present?
      external_publishers = ExternalPublisher.load_all_for_device(device)
      @partner_filtered_publishers = external_publishers.select { |e| @partner.name == e.partner_name }
    end
  end

end




