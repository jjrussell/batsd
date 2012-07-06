
module UserEventTypes
  include TypeConverters

  EVENT_TYPE_KEYS = [
    :invalid, :iap, :shutdown
  ]

  EVENT_TYPE_IDS = {
    :invalid  => 0,
    :iap      => 1,
    :shutdown => 2,
  }

  EVENT_TYPE_MAP = {

    # structure of this map:
    #
    # :event_type_name => {
    #   :required_field_1 => :data_type_1,
    #   :required_field_2 => :data_type_2,
    # }
    #
    # :data_type_X MUST match a key in TypeConverters::TYPES

    :invalid => {
    },

    :iap => {
      :currency_id    => :string,
      :name           => :string,
      :price          => :float,
      :quantity       => :int,
    },

    :shutdown => {
    },

  }
end
