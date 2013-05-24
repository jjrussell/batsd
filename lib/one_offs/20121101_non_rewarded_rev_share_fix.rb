class OneOffs
  def self.non_rewarded_rev_share_fix
    App.connection.execute <<-EOSQL
      update currencies
      set rev_share_override = 0.7
      where (rev_share_override < 0.7 or rev_share_override is null) and conversion_rate = 0;
    EOSQL
  end
end
