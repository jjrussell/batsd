class OneOffs

  def self.populate_network_costs_first_effective_on
    NetworkCost.find_each(:conditions => "first_effective_on is null") do |nc|
      nc.first_effective_on = nc.created_at.to_date + 1.day
      nc.save!
    end
  end

end
