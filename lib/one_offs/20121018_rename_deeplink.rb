# OneOffs.rename_deeplinks
# OneOffs.disable_glu_deeplinks
class OneOffs
  THRESHOLD = 10.seconds

  def self.rename_deeplinks
    last_time = Time.now

    # currently there are around 12,000 deeplink offers
    count = 0
    total = DeeplinkOffer.count
    puts_with_time("#{count}/#{total} DeeplinkOffer done")
    DeeplinkOffer.find_each do |deeplink|
      log_activity_and_save!(deeplink, 'rename_deeplinks') do
        deeplink.name = "Check out more ways to enjoy the apps you love at Tapjoy.com!"
        count += 1
        if Time.now - last_time > THRESHOLD
          puts_with_time("#{count}/#{total} DeeplinkOffer done")
          last_time = Time.now
        end
      end
    end

    conditions = ["item_type = ? and name like 'Earn % in %' ", 'DeeplinkOffer']
    count = 0
    total = Offer.where(conditions).count
    puts_with_time("#{count}/#{total} DeeplinkOffer done")
    Offer.where(conditions).find_each do |offer|
      log_activity_and_save!(offer, 'rename_deeplinks') do
        offer.name = "Check out more ways to enjoy the apps you love at Tapjoy.com!"
        count += 1
        if Time.now - last_time > THRESHOLD
          puts_with_time("#{count}/#{total} Offer done")
          last_time = Time.now
        end
      end
    end

    nil
  end

  def self.disable_glu_deeplinks
    last_time = Time.now
    count = 0
    total = Partner.find('28239536-44dd-417f-942d-8247b6da0e84').offers.where(:item_type => 'DeeplinkOffer', :user_enabled => true).count
    puts_with_time("#{count}/#{total} DeeplinkOffer done")
    Partner.find('28239536-44dd-417f-942d-8247b6da0e84').offers.where(:item_type => 'DeeplinkOffer', :user_enabled => true).each do |offer|
      log_activity_and_save!(offer, 'disable_glu_deeplinks') do
        offer.user_enabled = false
        count += 1
        if Time.now - last_time > THRESHOLD
          puts_with_time("#{count}/#{total} Offer done")
          last_time = Time.now
        end
      end
    end

    nil
  end

  private

  def self.log_activity_and_save!(object, action)
    activity_log                  = ActivityLog.new({ :load => false })
    activity_log.request_id       = self.generate_random_UUID
    activity_log.user             = 'script'
    activity_log.controller       = 'one_off'
    activity_log.action           = action
    activity_log.object           = object
    activity_log.included_methods = []

    yield

    if object.changed?
      object.save!
      activity_log.finalize_states
      activity_log.save
    end
  end

  def self.generate_random_UUID
    UUIDTools::UUID.random_create.to_s
  end

  def self.puts_with_time(str)
    puts "[#{Time.now.to_s}] #{str}"
  end
end
