FactoryGirl.define do

  factory :user_event do
    udid          { Factory.next(:udid) }
    app_id        { Factory.next(:guid) }
    event_type_id { Factory.next(:event_type_id) }

    after_build do |user_event|
      event_type_hash = UserEvent::EVENT_TYPE_IDS[user_event.event_type_id]
      data = UserEvent::EVENT_TYPE_DATA[event_type_hash]
      data.keys.each do |key|
        if UserEvent::EVENT_TYPE_DATA_TO_FACTORY.include?(key)
          data[key] = Factory.next(UserEvent::EVENT_TYPE_DATA_TO_FACTORY[key])
        else
          data[key] = Factory.next(key)
        end
      end
      user_event.data = data
    end
  end

end
