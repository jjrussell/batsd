FactoryGirl.define do
  sequence :name do |n|
    "Name #{n}"
  end

  sequence :email do |n|
    "user#{Time.now.to_f}@tapjoy.com"
  end

  sequence :udid do |n|
    "#{('0' * (40 - n.to_s.length))}#{n}"
  end

  sequence :guid do |n|
    "#{UUIDTools::UUID.random_create}"
  end

  sequence :integer do |n|
    n
  end

  sequence :event_type_id do |n|
    # TODO: make this work for new event types when there are more than 2
    (Time.zone.now % n).odd? ? 1 : 0
  end

end
