class OneOffs

  def self.populate_spend_shares
    Date.parse('2010-12-02').upto(Date.today) do |date|
      SpendShare.for_date(date)
    end
  end

end
