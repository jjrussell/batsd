class PayoutThresholdConfirmation < PayoutConfirmation
  CONFIRM_ROLES = %w( payout_manager account_mgr admin)
  protected
  def after_confirm
    partner.payout_threshold = partner.next_payout_amount * 1.1
  end

  def get_system_notes
    "SYSTEM: Payout is greater than or equal to #{NumberHelper.number_to_currency((partner.payout_threshold/100).to_f)}"
  end

  def get_allowable_roles
    CONFIRM_ROLES.clone
  end
end
