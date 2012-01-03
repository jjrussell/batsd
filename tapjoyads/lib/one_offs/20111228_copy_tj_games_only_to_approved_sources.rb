class OneOffs

  def self.copy_tj_games_only_to_approved_sources
    Offer.find_each(:conditions => 'tj_games_only = true') do |offer|
      offer.approved_sources = ['tj_games']
      offer.save!
    end
  end

end
