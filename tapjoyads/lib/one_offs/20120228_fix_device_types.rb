class OneOffs
  def self.fix_device_types
    offers = {}
    affected_offers = {}

    count = 0

    ActivityLog.select(:where => "`updated-at` is not null and object_type = 'Offer'", :order_by => "`updated-at` desc") do |activity_log|
      count +=1
      puts count if count % 50000 == 0
      next if activity_log.after_state['device_types'].nil?
      next if offers[activity_log.object_id].present?

      offer = Offer.find_by_id(activity_log.object_id)
      next if offer.nil?
      offer.device_types = activity_log.after_state['device_types']
      if offer.changed?
        puts "Offer #{offer.id} has been fixed from #{offer.device_types_was} to #{offer.device_types}"
        offer.save!
        affected_offers[offer.id] = offer
      end

      offers[offer.id] = true
    end

    return affected_offers
  end
end
