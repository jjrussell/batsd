
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


    # add a new `self.define_attr` line in user_event.rb for each new attribute defined here
    
    :invalid => {
    },

    :iap => {
      :currency_code  => :string,
      :name           => :string,
      :item_id        => :string,
      :price          => :float,
      :quantity       => :int,

      :REQUIRED       => [ :currency_code, :name, :item_id, :price, :quantity ],
      :ALTERNATIVES   => {
        :item_id        => [ :name ],
        :name           => [ :item_id ],
      }
    },

    :shutdown => {
    },

  }

  EVENT_TYPE_MAP.freeze()
  EVENT_TYPE_IDS.freeze()
  EVENT_TYPE_KEYS.freeze()
end
