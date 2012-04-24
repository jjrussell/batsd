class PayoutConfirmation < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  def confirm
    self.confirmed = true
    self.after_confirm if self.respond_to?(:after_confirm)
  end

  def unconfirm
    self.confirmed = false
  end

  def system_notes
    get_system_notes unless self.confirmed
  end

  def has_proper_role(user)
    (get_allowable_roles & user.role_assignments.map { |x| x.name}).present?
  end
end
