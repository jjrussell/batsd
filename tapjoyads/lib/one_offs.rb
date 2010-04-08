class OneOffs

  def self.import_conversions
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
        c.advertiser_app_id = vals[2].downcase unless vals[2] == 'NULL'
        c.publisher_app_id = vals[1].downcase
        c.advertiser_amount = vals[4].to_i
        c.publisher_amount = vals[3].to_i
        c.tapjoy_amount = vals[5].to_i + vals[6].to_i
        c.reward_type = 999
        c.created_at = Time.parse(vals[10] + ' CST').utc
        c.updated_at = Time.parse(vals[10] + ' CST').utc
        c.save!
      end
    end
    file.close
  end

end
