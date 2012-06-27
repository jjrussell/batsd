class UserEvent < WebRequest

  EVENT_TYPE_IDS = [ :IAP, :SHUTDOWN ]


  self.define_attr :data

  def initialize(options = {})
    options.delete(:action)
    options.delete(:controller)
    event_data    = options.delete(:data)                       { |k| {} }

    super(options, false)

    self.data     = event_data
  end

  def valid?
    ### TODO temporary code follows, will change when publishers can make their own events
    type_id = Integer(type) rescue nil
    if type_id == EVENT_TYPE_IDS.index(:IAP)
      local_data = to_hash_from_json(data)
      local_data.present? && local_data[:name].present? && price_valid?(local_data[:price])
    elsif type_id == EVENT_TYPE_IDS.index(:SHUTDOWN)
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
