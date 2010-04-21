class OneOffs

  def self.import_conversions
    file = File.open('tmp/conversions.txt', 'r')
    line_counter = 0
    file.each_line do |line|
      line_counter += 1
      puts "#{line_counter} - #{Time.now}" if line_counter % 500 == 0

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
        c.advertiser_app_id = vals[2].downcase unless vals[2] == 'NULL'
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
    end
    file.close
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
      Partner.find_each do |p|
        balance_sum = p.orders.sum(:amount)
        payouts_sum = p.payouts.sum(:amount)
        publisher_conversions_sum = 0
        p.apps.each do |a|
          balance_sum += a.advertiser_conversions.sum(:advertiser_amount)
          publisher_conversions_sum += a.publisher_conversions.sum(:publisher_amount)
        end
        p.balance = balance_sum
        p.pending_earnings = publisher_conversions_sum - payouts_sum
        p.save!
      end
    end
  end
  
end
