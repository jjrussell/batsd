class MailChimp
  def self.chimp
    Hominid::API.new(MAIL_CHIMP_API_KEY)
  end

  def self.lookup_user(email)
    chimp.list_member_info(MAIL_CHIMP_PARTNERS_LIST_ID, [email]).first.second.first
  end

  def self.update(email, merge_tags)
    chimp.list_update_member(MAIL_CHIMP_PARTNERS_LIST_ID, email, merge_tags)
  end

  # todo: remove "add_partner" and "add_partners"
  def self.add_partner(partner)
    add_partners([partner])
  end

  def self.add_partners(partners)
    errors = []
    partners.map do |partner|
      unless partner.non_managers.blank?
        email = partner.non_managers.first.email
        if email.blank? || (/mailinator\.com$|example\.com$|test\.com$/ =~ email)
          nil
        else
          name = partner.contact_name
          name = email if name.blank?
          email = 'dev@tapjoy.com' unless Rails.env.production?
          {
            'EMAIL' => email,
            'NAME' => name,
            'ID' => partner.id,
            'IS_PUB' => partner.has_publisher_offer? ? 'true' : 'false',
            'CAN_EMAIL' => 'true'
          }
        end
      end
    end.compact.each_slice(100) do |slice|
      results = chimp.list_batch_subscribe(MAIL_CHIMP_PARTNERS_LIST_ID, slice)
      errors << results["errors"]
    end
    errors.flatten
  end

  def self.add_user(user)
    partner = user.partners.first
    name = partner.contact_name
    name = user.email if name.blank?
    email = user.email
    email = 'dev@tapjoy.com' unless Rails.env.production?
    hash = {
      'EMAIL' => email,
      'NAME' => name,
      'ID' => partner.id,
      'IS_PUB' => partner.has_publisher_offer? ? 'true' : 'false',
      'CAN_EMAIL' => 'true'
    }
    chimp.list_subscribe(MAIL_CHIMP_PARTNERS_LIST_ID, user.email, hash)
  end
end
