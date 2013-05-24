class OneOffs
  def self.update_max_age_rating
    Currency.find_all_by_max_age_rating(4).each do |c|
      c.update_attribute(:max_age_rating, nil)
    end
  end
end
