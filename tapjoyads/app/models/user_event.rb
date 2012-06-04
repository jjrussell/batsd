class UserEvent < SyslogMessage

  EVENT_TYPE_IDS = [ :IAP, :SHUTDOWN ]

  self.define_attr :udid
  self.define_attr :app_id
  self.define_attr :type_id, :type => :int
  self.define_attr :data, :type => :json

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
      self.data.present? && self.data[:name].present? && price_valid?
    elsif self.type_id == EVENT_TYPE_IDS.index(:SHUTDOWN)
      self.data.blank?
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
