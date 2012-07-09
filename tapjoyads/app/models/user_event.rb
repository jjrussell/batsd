class UserEvent < WebRequest
  include UserEventTypes

  DEVICE_KEYS_TO_TRY = [ :udid, :mac_address, :android_id, :serial_id, :sha1_mac_address ]

  # add new event type fields here with their required types
  # make sure to assign them within #put_values() below
  # make sure changes here are reflected in user_event_types.rb
  self.define_attr :name
  self.define_attr :quantity, :type => :int
  self.define_attr :price,    :type => :float

  def put_values(args, ip_address, geoip_data, user_agent)

    # Use '' because the raised error message will show that event_type_id is blank and ''.to_i() computes to 0
    event_type_id = (args.delete(:event_type_id) { '' }).to_i
    if event_type_id > 0
      args[:type] = UserEventTypes::EVENT_TYPE_KEYS[event_type_id]
    else
      raise "#{event_type_id} is not a valid 'event_type_id'."
    end

    app = App.find_in_cache(args[:app_id])
    raise "App ID '#{args[:app_id]}' could not be found. Check 'app_id' and try again." unless app.present?    # TODO use i18n?
    device_id_key = DEVICE_KEYS_TO_TRY.detect { |key| args[key].present? }
    raise I18n.t('user_event.error.no_device') unless device_id_key.present?
    event_descriptor = UserEventTypes::EVENT_TYPE_MAP[args[:type]]
    missing_field, required_type = event_descriptor.detect { |field, type| args[field].blank? }
    raise "Expected attribute '#{missing_field}' of type '#{required_type}' not found." if missing_field
    invalid_field, required_type = event_descriptor.detect { |field, type| !TypeConverters::TYPES[type].from_string(args[field], true) }
    raise "Error assigning '#{invalid_field}' attribute. The value '#{args[invalid_field]}' is not of type '#{required_type}'." if invalid_field

    remote_verifier_hash = args.delete(:verifier)
    raise I18n.t('user_event.error.no_verifier') unless remote_verifier_hash.present?
    local_verifier_string = [ app.id, args[device_id_key], app.secret_key, UserEventTypes::EVENT_TYPE_IDS[args[:type]] ].join(':')
    raise I18n.t('user_event.error.verification_failed') unless Digest::SHA256.hexdigest(local_verifier_string) == remote_verifier_hash

    # assign new event type fields here
    # make sure to define new attributes with `self.define_attr` in the above block
    # make sure changes here are reflected in user_event_types.rb
    self.name     = args.delete(:name)
    self.quantity = args.delete(:quantity)
    self.price    = args.delete(:price)

    super(nil, args, ip_address, geoip_data, user_agent)
  end

end
