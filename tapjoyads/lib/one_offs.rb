class OneOffs
  
  def self.import_conversions
    Benchmark.realtime do
      file = File.open('tmp/conversions.txt', 'r')
      line_counter = 0
      file.each_line do |line|
        line_counter += 1
        
        # the first 2 lines are headers
        if line_counter < 3
          next
        end
        
        vals = line.split(' ', 11)
        
        # check to see if this line is a complete conversion record and not just a summary/blank line
        unless vals.length == 11
          puts "*** weird line ***"
          puts line
          next
        end
        
        if Conversion.find_by_id(vals[0].downcase).nil?
          c = Conversion.new
          c.id = vals[0].downcase
          c.reward_id = vals[7].downcase unless vals[7] == 'NULL'
          c.advertiser_offer = Offer.find_by_item_id(vals[2].downcase) unless vals[2] == 'NULL'
          c.publisher_app_id = vals[1].downcase
          c.advertiser_amount = vals[4].to_i
          c.publisher_amount = vals[3].to_i
          c.tapjoy_amount = vals[5].to_i + vals[6].to_i
          c.reward_type = 999
          c.created_at = Time.parse(vals[10] + ' CST').utc
          c.updated_at = Time.parse(vals[10] + ' CST').utc
          begin
            c.save!
          rescue Exception => e
            puts "*** retrying *** #{e.message}"
            retry
          end
        end
        puts "#{Time.zone.now} - finished #{line_counter} conversions" if line_counter % 1000 == 0
      end
      file.close
    end
  end
  
  def self.get_udids(app_id, output_file)
    file = File.open(output_file, 'w')
    20.times do |i|
      counter = 0
      SimpledbResource.select(:domain_name => "device_app_list_#{i}", :where => "`app.#{app_id}` != ''") do |device|
        organic_paid = "organic"
        click = StoreClick.new(:key => "#{device.key}.#{app_id}")
        organic_paid = "paid" if click && click.get('installed')
        file.puts "#{device.key}, #{organic_paid}"
        counter += 1
        puts "Finished #{counter}" if counter % 100 == 0
      end
      puts "Completed device_app_list_#{i}"
    end
    file.close
  end
  
  def self.calculate_partner_balances
    Benchmark.realtime do
      counter = 0
      Partner.find_each do |p|
        counter += 1
        orders_sum = p.orders.sum(:amount)
        payouts_sum = p.payouts.sum(:amount)
        publisher_conversions_sum = 0
        advertiser_conversions_sum = 0
        p.apps.each do |a|
          publisher_conversions_sum += a.publisher_conversions.sum(:publisher_amount)
        end
        p.offers.each do |o|
          advertiser_conversions_sum += o.advertiser_conversions.sum(:advertiser_amount)
        end
        p.balance = orders_sum + advertiser_conversions_sum
        p.pending_earnings = publisher_conversions_sum - payouts_sum
        p.save!
        puts "finished #{counter} partners" if counter % 100 == 0
      end
    end
  end
  
  def self.remove_dup_conversions
    Conversion.find_each(:conditions => []) do |c|
      
    end
  end
  
end
