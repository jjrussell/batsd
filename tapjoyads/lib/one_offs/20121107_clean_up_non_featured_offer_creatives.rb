# OneOffs.clean_up_non_featured_offer_creatives
class OneOffs

  def self.clean_up_non_featured_offer_creatives
    failed_hash, removed_hash = {}, {}
    Offer.where(:featured => false).find_each do |offer|
      next if offer.banner_creatives && offer.banner_creatives.empty?

      # Find creatives that shouldn't be there.
      featured_sizes = offer.banner_creatives - Offer::DISPLAY_AD_SIZES
      next if featured_sizes.empty?

      # Apparently banner creatives can only be removed one at a time...
      err = false
      featured_sizes.each do |size|
        begin
          offer.remove_banner_creative(size)
          raise unless (offer.banner_creatives_changed? && offer.save)
        rescue
          err = true
          break
        end
      end

      if err
        failed_hash[offer.id] = featured_sizes
        puts "Failed to remove #{featured_sizes.length} invalid creative size(s) from offer #{offer.id}."
      else
        removed_hash[offer.id] = featured_sizes
        puts "Removed #{featured_sizes.length} invalid creative size(s) from offer #{offer.id}."
      end
    end

    self.print_summary(removed_hash)
    self.print_summary(failed_hash, false) unless failed_hash.empty?
  end

  def self.print_summary(offer_hash, removed = true)
    count = offer_hash.values.flatten.length

    if removed
      puts "\nFound #{offer_hash.length} non-rewarded offers with incorrect banner creative sizes."
      puts "#{count} incorrect sizes were successfully removed."
    else
      puts "\n\n**FAILED** to remove the following #{count} sizes:"
    end
    offer_hash.each { |id, sizes| puts "Offer #{id}: #{sizes.join(', ')}" }

  end

end

