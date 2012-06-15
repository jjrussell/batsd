class UserEvent < SyslogMessage

  EVENT_TYPE_IDS = [ :IAP, :SHUTDOWN ]

  self.define_attr :udid
  self.define_attr :app_id
  self.define_attr :type_id, :type => :int
  self.define_attr :data, :type => :json

  ERROR_APP_ID_OR_UDID_MSG  = "Could not find app or device. Check your app_id and udid paramters.\n"
  ERROR_EVENT_INFO_MSG      = "Error parsing the event info. For shutdown events, ensure the data field is empty or nonexistent. For IAP events, ensure you provided an item name, a currency name, and a valid float for the price.\n"
  SUCCESS_MSG               = "Successfully saved user event.\n"

  def initialize(options = {})
    options.delete(:action)
    options.delete(:controller)
    udid          = options.delete(:udid)                       { |k| raise "#{k} is a required argument" }
    app_id        = options.delete(:app_id)                     { |k| raise "#{k} is a required argument" }
    event_type_id = options.delete(:event_type_id)              { |k| raise "#{k} is a required argument" }
    event_data    = options.delete(:data)                       { |k| {} }

    super(options, false)

    self.udid     = udid
    self.app_id   = app_id
    self.type_id  = event_type_id
    self.data     = event_data
  end

  def valid?
    ### TODO temporary code follows, will change when publishers can make their own events
    if self.type_id == EVENT_TYPE_IDS.index(:IAP)
      local_data = to_hash_from_json(data)
      local_data.present? && local_data[:name].present? && price_valid?(local_data[:price])
    elsif self.type_id == EVENT_TYPE_IDS.index(:SHUTDOWN)
      self.data.blank?
    else
      false
    end
    ### END TODO
  end

  private

  def to_hash_from_json(data)
    hashed_data = {}
    data.to_hash.each do |key, val|
      hashed_data[key.to_sym] = val
    end
    hashed_data
  end

  def price_valid?(price)
    # this could be module-ized and used as a general #numeric? method
    true if Float(price) rescue false
  end


end
