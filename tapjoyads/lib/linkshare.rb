class Linkshare

  def self.add_params(url, affiliate = nil)
    if url =~ /^http:\/\/phobos\.apple\.com/
      if affiliate == 'tradedoubler'
        url += '&partnerId=2003&tduid=UK1800811'
      else
        url += '&partnerId=30&siteID=OxXMC6MRBt4'
      end
    end
    url
  end

end
