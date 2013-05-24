class OneOffs
  def self.wipe_clients_table
    Client.delete_all
  end

  def self.add_inactive_client
    inactive_clients = Client.new
    inactive_clients.name = "Inactive Clients"
    inactive_clients.save

    Partner.update_all(:client_id => nil)
  end

  def self.populate_clients_from_csv
    s3_filename = 'updated_client_table.csv'
    file = Tempfile.new(s3_filename)

    puts "Downloading #{s3_filename}"
    file.write(S3.bucket(BucketNames::TAPJOY).objects[s3_filename].read)
    file.rewind

    puts "Importing rows..."
    inactive_client = Client.find_by_name("Inactive Clients")
    row_id = 0
    CSV.open(file.path, 'r') do |partner_id, client_name, partner_name, payment_type, _, _|
      begin
        row_id += 1
        next if row_id == 1
        printf "."

        if client_name == '#REF!'
          puts "\n#{row_id}. #REF! #{partner_id}, #{partner_name}, #{client_name}, #{payment_type}"
        end

        if payment_type.downcase == "inactive"
          client = inactive_client
        else
          client = Client.find_or_create_by_name(client_name)
          client.update_attributes!(:payment_type => payment_type)
        end

        partner = Partner.find_by_id(partner_id)
        unless partner
          puts "\n#{row_id}. Partner id not found. #{partner_id}, #{partner_name}, #{client_name}, #{payment_type}"
        end
        if partner.name != partner_name
          puts "\n#{row_id}. Partner name doesn't match. (#{partner.name}) #{partner_id}, #{partner_name}, #{client_name}, #{payment_type}"
        end

        partner.client_id = client.id
        # Partner has a validation that fails if client_id is changed. It also
        # has issues with clients that have Tapjoy in their names.
        partner.save(:validate => false)
      rescue => e
        puts "Died while processing row #{row_id}. #{partner_id}, #{partner_name}, #{client_name}, #{payment_type}"
        raise e
      end
    end
    puts "\nDone."
  end
end
