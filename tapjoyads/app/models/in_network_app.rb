class InNetworkApp

  attr_accessor :app_id, :app_name, :partner_name, :last_run_time, :currencies, :in_network_app_metadata

  def initialize(external_publisher, app_metadata = nil, last_run_time = nil)
    self.app_id = external_publisher.app_id
    self.app_name = external_publisher.app_name
    self.partner_name = external_publisher.partner_name
    self.last_run_time = last_run_time.to_i if last_run_time
    self.currencies = external_publisher.currencies
    self.in_network_app_metadata = app_metadata.in_network_app_metadata if app_metadata
  end

  def self.find_by_store_name_and_store_id(store_name, store_id)
    app_metadata = AppMetadata.find_by_store_name_and_store_id(store_name, store_id)
    if app_metadata
      app_metadata_mapping = AppMetadataMapping.find_by_app_metadata_id(app_metadata.id)
      if app_metadata_mapping
        external_publisher = ExternalPublisher.find_by_app_id(app_metadata_mapping.app_id)
        in_network_app = self.new(external_publisher, app_metadata)
      end
    end
    in_network_app
  end

end
