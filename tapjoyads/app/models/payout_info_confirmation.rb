class PayoutInfoConfirmation < PayoutConfirmation
  private
  CONFIRM_ROLES = %w(payout_manager)

  protected
  def get_system_notes
    'SYSTEM: Partner Payout Information has changed.'
  end

  def get_allowable_roles
    CONFIRM_ROLES.clone
  end
end
