class OneOffs
  def self.remove_duplicate_facebook_associations
    results = GamerProfile.find_by_sql("SELECT facebook_id, COUNT(*) AS acct_count FROM gamer_profiles WHERE facebook_id IS NOT NULL GROUP BY facebook_id  HAVING acct_count > 1")
    results.each do |result|
      Gamer.find(
        :all,
        :conditions => { :gamer_profiles => { :facebook_id => result.facebook_id } },
        :include => :gamer_profile,
        :order => 'last_login_at DESC',
        :limit => result.acct_count.to_i + 10, #just to be comfortable
        :offset => 1
      ).each do |gamer|
        gamer.gamer_profile.dissociate_account!(Invitation::FACEBOOK)
      end
    end
  end
end
