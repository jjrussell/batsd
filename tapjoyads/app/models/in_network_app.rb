class InNetworkApp

  attr_accessor :app_id, :app_name, :partner_name, :last_run_time, :currencies, :in_network_app_metadata

  def initialize(app, last_run_time = nil)
    self.app_id = app.id
    self.app_name = app.name
    self.partner_name = app.primary_app_metadata.try(:developer)
    self.partner_name = app.partner_name if partner_name.blank?
    self.last_run_time = last_run_time.to_i if last_run_time

    app.currencies.each do |currency|
      add_currency(currency)
    end

    set_in_network_app_metadata(app.id)
  end

  def self.find_by_store_name_and_store_id(store_name, store_id)
    app_metadata = AppMetadata.find_by_store_name_and_store_id(store_name, store_id)
    app_metadata_mapping = AppMetadataMapping.find_by_app_metadata_id(app_metadata.id) if app_metadata
    in_network_app = self.new(app_metadata_mapping.app) if app_metadata_mapping
    in_network_app
  end

  private

  def add_currency(currency)
    self.currencies ||= []
    self.currencies << { :id => currency.id,
                                :name => currency.name,
                                :udid_for_user_id => currency.udid_for_user_id,
                                :tapjoy_managed => currency.tapjoy_managed? }
  end

  def set_in_network_app_metadata(app_id)
    app_metadata_mapping = AppMetadataMapping.find_by_app_id(app_id)
    app_metadata = app_metadata_mapping.app_metadata if app_metadata_mapping

    self.in_network_app_metadata = app_metadata.in_network_app_metadata if app_metadata
  end

end
