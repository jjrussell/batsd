class OneOffs
  def self.add_vouchers_domain
    Voucher.create_domain('vouchers')
  end
end
