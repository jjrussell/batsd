class OneOffs
  def self.approve_custom_banner_creatives
    print 'Approving all banner creatives...'
    Offer.update_all("approved_banner_creatives = banner_creatives", :conditions => 'banner_creatives is not null')
    puts ' Done!'
  end
end
