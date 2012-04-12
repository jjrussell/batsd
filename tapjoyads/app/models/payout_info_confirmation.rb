class PayoutInfoConfirmation < PayoutConfirmation
  CONFIRM_ROLES = %w(account_mgr)

  protected
  def get_system_notes
    'SYSTEM: Partner Payout Information has changed.'
  end
end
