class OneOffs
  def self.update_gamer_tos_version
    Gamer.find_each do |gamer|
      gamer.accepted_tos_version = 1
      gamer.save!
    end
  end
end
