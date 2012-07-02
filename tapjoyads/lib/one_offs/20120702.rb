class OneOffs
  def self.convert_secondary_action_source_to_secondary
    video_button_ids = VideoButton.select(:id).all.map(&:id)
    tracking_offers  = Offer.where(:tracking_for_id => video_button_ids, :tracking_for_type => 'VideoButton').group(:tracking_for_id).map(&:id)
    puts "Updating #{tracking_offers.size} offers, who knows how many clicks"

    tracking_offers.each do |offer_id|
      print "#{offer_id}\t"
      Click.find_all_by_offer_id(offer_id).each do |click|
        print '.'
        click.put('source', 'secondary')
        click.save
      end
      puts "!"
    end

    puts "Success!"
  end
end