class UserEvent < WebRequest
  include UserEventTypes


  # add new event type fields here with their required types
  # make sure to assign them within the bottom of #put_values() below
  # make sure changes here are reflected in user_event_types.rb
  self.define_attr :name
  self.define_attr :currency_code
  self.define_attr :item_id
  self.define_attr :quantity, :type => :int
  self.define_attr :price,    :type => :float

  def initialize(event_type, event_data)
    validate!(event_type, event_data)
    super()
    self.type = event_type

    # assign new event type fields here
    # make sure to define new attributes with `self.define_attr` in the above block
    # make sure all attributes used here are defined for this event type in user_event_types.rb
    self.name           = event_data.delete(:name)
    self.item_id        = event_data.delete(:item_id)
    self.currency_code  = event_data.delete(:currency_code)
    self.quantity       = event_data.delete(:quantity)
    self.price          = event_data.delete(:price)

    # MAKE SURE TO CALL #.put_values() AFTER #.new() TO POPULATE GENERAL WEB REQUEST PARAMS BEFORE SAVING!!!
  end

  def self.verifier_string(app_id, device_id, secret_key, event_type_id, event_data)
    verifier_array = [ app_id, device_id, secret_key, event_type_id ]
    if event_data.present?
      verifier_array += event_data.keys.sort.map { |key| event_data[key] }
    end
    Digest::SHA256.hexdigest(verifier_array.join(':'))
  end

  private

  def validate!(event_type, event_data)
    event_descriptor = {}
    required_fields = []
    alternative_fields_map = {}
    UserEventTypes::EVENT_TYPE_MAP[event_type].each do |event_specific_field, data_type|
      if :REQUIRED == event_specific_field
        required_fields = data_type
      elsif :ALTERNATIVES == event_specific_field
        alternative_fields_map = data_type
      else
        event_descriptor[event_specific_field] = data_type
      end
    end
    check_for_missing_fields!(event_descriptor, event_data, required_fields, alternative_fields_map)
    check_for_undefined_fields!(event_descriptor, event_data)
    check_for_invalid_fields!(event_descriptor, event_data)
  end

  def check_for_missing_fields!(event_descriptor, event_data, required_fields, alternative_fields_map)
    missing_fields = required_fields.reject { |field| event_data[field].present? }
    alternative_fields_map.each do |field, alternatives|
      alternatives.each do |alternative|
        missing_fields.delete(field) if missing_fields.include?(field) && event_data[alternative].present?
      end
    end
    if missing_fields.present?
      raise "Expected attribute(s) #{missing_fields.join("\n")} not found."
    end
  end

  def check_for_undefined_fields!(event_descriptor, event_data)
    undefined_fields = event_data.keys.reject { |key| event_descriptor.has_key?(key) }
    if undefined_fields.present?
      raise "Attribute(s) #{undefined_fields.join(',')} are undefined for this event type."
    end
  end

  def check_for_invalid_fields!(event_descriptor, event_data)
    invalid_fields = event_data.reject { |field, value| TypeConverters::TYPES[event_descriptor[field]].from_string(value, true) }
    if invalid_fields.present?
      raise invalid_fields.keys.map { |field| "'#{field}' is not of type '#{event_descriptor[field]}'." }.join("\n")
    end
  end

end
