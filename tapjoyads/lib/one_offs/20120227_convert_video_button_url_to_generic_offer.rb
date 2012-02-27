class OneOffs
  def self.convert_video_button_urls_to_generic_offers
    failed = []

    VideoButton.all(:conditions => ['url IS NOT NULL']).each do |button|
      button.item = GenericOffer.new(
        :partner  => button.video_offer.partner,
        :name     => "#{button.video_offer.name} - #{button.name}",
        :url      => button.url
      )
      failed << button unless button.save
    end

    if failed.empty?
      puts "No conversions failed!"
    else
      word = failed.size == 1 ? 'conversion' : 'conversions';
      puts "#{failed.size} #{word} failed!"
      puts "  #{failed.map(&:id).join("\n  ")}"
    end

    failed
  end
end
