class OneOffs
  def self.refund_partners
    DEC_PARTNERS_TO_FIX.each do |partner|
      partner_id = partner.first
      amount = (partner.second * 100).to_i
      Order.create!(:partner_id => partner_id, :status => 1, :payment_method => 1, :amount => amount,
        :note => "Good faith credit for poor performing campaign. (Dec)", :description => "Good faith credit for poor performing campaign. (Dec)") rescue puts "#{Partner.find(partner_id).name} #{partner_id}"
    end

    JAN_PARTNERS_TO_FIX.each do |partner|
      partner_id = partner.first
      amount = (partner.second * 100).to_i
      Order.create!(:partner_id => partner_id, :status => 1, :payment_method => 1, :amount => amount,
        :note => "Good faith credit for poor performing campaign. (Jan)", :description => "Good faith credit for poor performing campaign. (Jan)") rescue puts "#{Partner.find(partner_id).name} #{partner_id}"
    end
  end
end
