class OneOffs

  def self.set_account_type_to_gamers
    Gamer.all.each do |gamer|
      gamer.update_attribute(:account_type, Gamer::ACCOUNT_TYPE[:email_signup])
    end
  end

end
