class OneOffs
  def self.eliminate_north_korea
    sql = "SELECT * FROM offers WHERE countries LIKE '%kp%'"
    offers = Offer.find_by_sql(sql)
    puts "Before: #{offers.length}"

    offers.each do |offer|
      offer.countries = offer.get_countries - ['KP'] + ['KR']
      offer.save
    end

    puts "After: #{Offer.find_by_sql(sql).length}"
  end
end
