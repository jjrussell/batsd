class UserEvent < WebRequest
  include UserEventTypes

  REQUIRED_KEYS = [ :app_id, :event_type_id, :udid ]

  self.define_attr :name
  self.define_attr :event_type
  self.define_attr :quantity, :type => :int
  self.define_attr :price,    :type => :float

  def initialize(options = {})
    verify_options(options)
    super(options, false)
    validate_event(options)
  end

  private

  def validate_event(options)
      self.event_type = UserEventTypes::EVENT_TYPE_KEYS[options[:event_type_id].to_i]
    if self.event_type != :invalid
      event_descriptor = UserEventTypes::EVENT_TYPE_MAP[key]
      event_descriptor.each do |required_key, expected_data_type|
        converter = TypeConverter::TYPES[expected_data_type]
        unless converter.try(:from_string, expected_data_type, true)
          raise "Error assigning '#{required_key}' attribute. The value '#{options[required_key]}' is not of type '#{expected_data_type}."    # TODO use i18n?
        end
        send("#{required_key}=", options[required_key])
      end
    end
  end

  def verify_options(options)
    verifier = options.delete(:verifier)
    raise t('user_event.error.no_verifier') unless verifier.present?
    event_type_key = UserEventTypes::EVENT_TYPE_KEYS[options[:event_type_id].to_i]
    raise "#{options[:event_type_id]} is not a valid 'event_type_id'." if :invalid == event_type_key    # TODO use i18n?
    values = []
    required_keys = (REQUIRED_KEYS + UserEventTypes::EVENT_TYPE_MAP[event_type_key].keys)
    required_keys.sort.each do |required_key|
      if options.has_key?(required_key)
        values << options[required_key]
      else
        raise "Expected attribute '#{required_key}' of type '#{UserEventTypes::EVENT_TYPE_MAP[event_type_key][required_key]}' not found."    # TODO use i18n?
      end
    end
    string_to_be_verified = values.join(':')
    app = App.find_in_cache(options[:app_id])
    raise "App ID #{options[:app_id]} could not be found. Check 'app_id' and try again." unless app
    if verifier != Digest::SHA1.digest(app.secret_key + string_to_be_verified)
      raise t('user_event.error.verification_failed')
    end
  end
end
