class UserEvent < SyslogMessage

  EVENT_TYPE_IDS = [ :IAP, :SHUTDOWN ]

  EVENT_TYPE_DATA = {
    :IAP => [:name, :price],
    :SHUTDOWN => [],
  }

  EVENT_TYPE_DATA_TO_FACTORY = {
    :price => :integer,
  }

  self.define_attr :udid
  self.define_attr :app_id
  self.define_attr :type_id
  self.define_attr :data, :type => :json

  def initialize(options = {})
    options.delete(:action)
    options.delete(:controller)
    udid          = options.delete(:udid)           { |k| raise "#{k} is a required argument" }
    app_id        = options.delete(:app_id)         { |k| raise "#{k} is a required argument" }
    event_type_id = options.delete(:event_type_id)  { |k| raise "#{k} is a required argument" }
    event_data    = options.delete(:data)           { |k| [] }

    super(options)

    self.udid     = udid
    self.app_id   = app_id
    self.type_id  = event_type_id
    self.data     = event_data
  end

  def valid?
    ### TODO temporary code follows, will change when publishers can make their own events
    if UserEvent.EVENT_TYPE_IDS[self.type_id] == '0'   # IAP event
      self.data.present? && self.data[:name] && price_valid?
    elsif UserEvent.EVENT_TYPE_IDS[self.type_id] == '1'
      self.data.blank?   # shutdown event
    else
      false
    end
    ### END TODO
  end

  private

  def price_valid?
    # this could be module-ized and used as a general #numeric? method
    true if Float(self.data[:price]) rescue false
  end


end
