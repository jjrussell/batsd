class OneOffs
  def self.set_default_user_country
    User.update_all('country = "N/A"', 'country IS NULL');
  end
end
