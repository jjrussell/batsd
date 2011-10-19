class OneOffs
  def self.update_gamer_tos_version
    Gamer.connection.execute("update gamers set accepted_tos_version = 1")
  end
end
