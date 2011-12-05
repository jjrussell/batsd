class OneOffs

  def self.add_uncapped_ratios_to_spend_shares
    SpendShare.find_each do |s|
      s.uncapped_ratio = s.ratio
      s.ratio = [s.uncapped_ratio, SpendShare::MIN_RATIO].max
      s.save!
    end
  end

end
