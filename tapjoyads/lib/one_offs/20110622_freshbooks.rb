class OneOffs
  def self.fill_in_billing_emails_from_freshbooks
    missing_pairs = []
    FreshBooks.client_list.each do |client|
      email = client[:email]
      id = client[:client_id]
      if email.match(/tapjoy|offerpal/)
        puts "skipping internal email: #{email}"
        next
      end
      user = User.find_by_email(email)

      if user
        user.partners.each do |partner|
          if partner.billing_email
            puts "partner #{partner.name} has email: #{partner.billing_email}, not using: #{email}"
          else
            puts "adding billing email #{email} to #{partner.name}"
            partner.freshbooks_client_id = id
            partner.billing_email = email
            partner.save!
          end
        end
      else
        missing_pairs << [id, email]
      end
    end

    missing_pairs.each do |id, email|
      email.match(/\w+@(\w+)\.\w/)
      if ['yahoo', 'gmail', 'me'].include? $1
        puts "uncertain what to do with email: #{email} - skipping"
        next
      end
      Partner.find(:all, :conditions => ["name like ?", $1]).each do |partner|
        if partner.billing_email
          puts "partner #{partner.name} has email #{partner.billing_email}, not using: #{email}"
        else
          puts "adding billing email #{email} to #{partner.name}"
          partner.freshbooks_client_id = id
          partner.billing_email = email
          partner.save!
        end
      end
    end
  end

  def self.internal_freshbooks_emails
    emails = []
    FreshBooks.client_list.each do |client|
      emails << client[:email] if client[:email].match(/tapjoy|offerpal/)
    end
    emails
  end

  def self.duplicate_freshbooks_emails
    client_counts = {}
    FreshBooks.client_list.each do |client|
      client_counts[client[:email]] ||= 0
      client_counts[client[:email]] += 1
    end
    client_counts.each do |email, count|
      puts "#{email} - #{count} clients" if count != 1
    end
    client_counts.select { |email, count| count != 1 }
  end
end
