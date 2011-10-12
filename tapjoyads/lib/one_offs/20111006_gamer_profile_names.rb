class OneOffs
  def self.migrate_gamer_profile_names
    GamerProfile.find_each(:conditions => 'gamer_profiles.first_name is not null or gamer_profiles.last_name is not null') do |profile|
      if (profile.first_name.blank?)
        profile.name = profile.last_name
      elsif (profile.last_name.blank?)
        profile.name = profile.first_name
      else
        profile.name = "#{profile.first_name} #{profile.last_name}"
      end
      profile.save!
    end
  end
end
