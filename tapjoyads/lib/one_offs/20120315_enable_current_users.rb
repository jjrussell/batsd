class OneOffs
  def self.enable_current_users
    User.update_all('state = "approved"')
  end
end
