class MailChimp
  def self.chimp
    @chimp ||= Hominid::Base.new({:api_key => MAIL_CHIMP_API_KEY})
  end

  def self.get_lists
    @lists ||= chimp.lists
  end

  def self.add_partner(partner)
    add_partners([partner])
  end

  def self.add_partners(partners)
    list = partners.map do |partner|
      {
        'EMAIL' => partner.users.first.email,
        'NAME' => partner.contact_name,
        'ID' => partner.id,
        'ADV_TIER' => partner.advertiser_tier,
        'PUB_TIER' => partner.publisher_tier
      }
    end
    chimp.subscribe_many(MAIL_CHIMP_PARTNERS_LIST_ID, list)
  end
end
