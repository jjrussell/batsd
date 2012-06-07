class OneOffs

  def self.fix_confirmations_migrate
    Partner.connection.execute('update `partners` set `payout_threshold_confirmation` = case when (`next_payout_amount` < `payout_threshold` ) then 1 else 0 end')
  end
end
