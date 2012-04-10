class PayoutThresholdConfirmation < PayoutConfirmation
  CONFIRM_ROLES = %w( payout_manager account_mgr)

  private
  def get_system_notes
    "SYSTEM: Payout is greater than or equal to #{NumberHelper.number_to_currency((partner.payout_threshold/100).to_f)}"
  end
end
