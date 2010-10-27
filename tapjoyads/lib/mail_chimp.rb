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

  def self.lookup_user_id(email)
    chimp.member_info(MAIL_CHIMP_PARTNERS_LIST_ID, email)["id"]
  end

  def self.add_partners(partners)
    errors = []
    partners.map do |partner|
      email = partner.non_managers.first.email
      if email.blank?
        nil
      else
        name = partner.contact_name
        name = email if name.blank?
        {
          'EMAIL' => email,
          'NAME' => name,
          'ID' => partner.id,
          'IS_PUB' => partner.has_publisher_offer? ? 'true' : 'false'
        }
      end
    end.compact.each_slice(100) do |slice|
      results = chimp.subscribe_many(MAIL_CHIMP_PARTNERS_LIST_ID, slice)
      errors << results["errors"]
    end
    errors.flatten
  end
end
