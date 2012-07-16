class UserEvent < WebRequest
  include UserEventTypes

  class UserEventInvalid < RuntimeError
  end


  # add new event type fields here with their required types
  # make sure to assign them at the bottom of #put_values() below
  # make sure changes here are reflected in user_event_types.rb
  self.define_attr :name
  self.define_attr :currency_code
  self.define_attr :item_id
  self.define_attr :quantity, :type => :int
  self.define_attr :price,    :type => :float

  def initialize(event_type, event_data = {})
    super()
    validate!(event_type, event_data)
    self.type = event_type

    # assign new event type fields here
    # make sure to define new attributes with `self.define_attr` in the above block
    # make sure all attributes used here are defined for this event type in user_event_types.rb
    event_data.each do |field, value|
      send("#{field}=", value)
    end

    # MAKE SURE TO CALL #.put_values() AFTER #.new() TO POPULATE GENERAL WEB REQUEST PARAMS BEFORE SAVING!!!
  end

  def self.generate_verifier_key(app_id, device_id, secret_key, event_type_id, event_data = {})
    verifier_array = [ app_id, device_id, secret_key, event_type_id ] 
    if event_data.present?
      event_data.keys.sort.map { |key| verifier_array << event_data[key] }
    end
    Digest::SHA256.hexdigest(verifier_array.join(':'))
  end

  private

  def validate!(event_type, event_data = {})
    event_descriptor        = {}
    required_fields         = []
    alternative_fields_map  = {}

    UserEventTypes::EVENT_TYPE_MAP[event_type].each do |event_specific_field, data_type|
      case event_specific_field
      when :REQUIRED      then required_fields        = data_type
      when :ALTERNATIVES  then alternative_fields_map = data_type
      else event_descriptor[event_specific_field]     = data_type
      end
    end

    check_for_missing_fields!(event_descriptor, required_fields, alternative_fields_map, event_data)
    check_for_undefined_fields!(event_descriptor, event_data)
    check_for_invalid_fields!(event_descriptor, event_data)
  end

  def check_for_missing_fields!(event_descriptor, required_fields = [], alternative_fields_map = {}, event_data = {})
    missing_fields = required_fields.reject do |field|
      event_data[field].present? || alternative_fields_map[field].any? { |alt| event_data[alt].present? }
    end

    if missing_fields.present?
      error_msg_data = { :missing_fields_string => missing_fields.join(',') }
      raise UserEventInvalid, I18n.t('user_event.error.missing_fields', error_msg_data)
    end
  end

  def check_for_undefined_fields!(event_descriptor, event_data = {})
    return unless event_data.present?
    undefined_fields = event_data.keys.reject { |key| event_descriptor.has_key?(key) }

    if undefined_fields.present?
      error_msg_data = { :undefined_fields_string => undefined_fields.join(',') }
      raise UserEventInvalid, I18n.t('user_event.error.undefined_fields', error_msg_data)
    end
  end

  def check_for_invalid_fields!(event_descriptor, event_data = {})
    return unless event_data.present?
    invalid_fields = event_data.reject { |field, value| TypeConverters::TYPES[event_descriptor[field]].from_string(value, true) }

    if invalid_fields.present?
      error_msgs = invalid_fields.keys.map do |field|
        I18n.t('user_event.error.invalid_field', { :field => field, :type => event_descriptor[field] })
      end
      raise UserEventInvalid, error_msgs.join("\n")
    end
  end

end
