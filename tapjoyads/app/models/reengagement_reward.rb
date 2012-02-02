class ReengagementReward
  self.domain_name = 'reengagement_reward'

  self.sdb_attr :user_id
  self.sdb_attr :app_id
  self.sdb_attr :currency_id
  self.sdb_attr :reengagement_offer_id
  self.sdb_attr :timestamp,     :type => :int
  self.sdb_attr :day_number,    :type => :int
  self.sdb_attr :reward_value,  :type => :int

end
