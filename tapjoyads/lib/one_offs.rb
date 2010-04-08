class OneOffs

  def self.import_conversions
    file = File.open('tmp/conversions.txt', 'r')
    first_line = true
    file.each_line do |line|

      # nasty hack alert!
      # for some reason the first line of this imput file doesn't work so just print
      # it and manually insert the record
      if first_line
        puts "*** first line ***"
        puts line
        first_line = false
        next
      end

      vals = line.split(' ', 11)
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
        c.reward_type = vals[9].to_i
        c.reward_type = 999 if c.reward_type == 6
        c.created_at = Time.zone.parse(vals[10])
        c.save!
      end
    end
    file.close
  end

end
