class OneOffs
  def self.set_valid_partners_to_confirm
    Partner.connection.execute('update partners as p inner join payouts ps on p.id = ps.partner_id set p.confirmed_for_payout = 1 where ps.status = 1 and ps.month = 1 and ps.year = 2012 and ps.payment_method = 1');
  end
end
