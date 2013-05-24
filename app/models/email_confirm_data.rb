require 'adapter'
class EmailConfirmData
  include Toy::Store
  adapter :redis, $redis

  timestamps

  attribute :accept_language_str, String
  attribute :content, String
  attribute :device_type, String
  attribute :geoip_data, Hash
  attribute :os_version, String
  attribute :selected_devices, String
  attribute :user_agent_str, String

  after_create :expire

  def to_hash()
    attributes.symbolize_keys
  end

  def expire()
    adapter.client.expire(adapter.key_for(id), 1.month)
  end
end
