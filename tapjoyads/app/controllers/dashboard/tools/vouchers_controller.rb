class Dashboard::Tools::VouchersController < Dashboard::DashboardController

  def show
    verify_params([ :id ])
    @coupon = Coupon.find_in_cache(params[:id])
    @vouchers = Voucher.select(:where => "coupon_id = '#{@coupon.id}'")[:items]
    verify_records([ @coupon, @vouchers ])
  end

end
