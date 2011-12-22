class OneOffs
  def self.approve_custom_banner_creatives
    print 'Approving all banner creatives'
    Offer.all.inject(0) do |count, offer|
      print '.' if count % 500 == 0
      offer.approved_banner_creatives = offer.banner_creatives
      offer.save
      count + 1
    end
    puts ' Done!'
  end
end
