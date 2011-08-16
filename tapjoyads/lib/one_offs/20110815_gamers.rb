class OneOffs
  def self.assign_confirmation_token_gamers
    Gamer.find_each do |gamer|
      gamer.confirmation_token = gamer.perishable_token
      gamer.save!
    end
  end
end
